const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();
const dbAsync = db.promise();

app.use(cors());
app.use(express.json());

// Test API connection
app.get('/health', (req, res) => {
  res.json({
    message: 'SafeDrive API is running!'
  });
});

// Get all registered drivers
app.get('/users', (req, res) => {
  db.query('SELECT userID, username, email FROM user',
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      res.json(results);
    }
  );
});

// Sign Up / register a new user
app.post('/register', (req, res) => {
  const {
    username,
    email,
    phone,
    password,
    vehicle_type,
    plate_number
  } = req.body;

  // Check required fields
  if (
    !username ||
    !email ||
    !phone ||
    !password ||
    !vehicle_type ||
    !plate_number
  ) {
    return res.status(400).json({
      message: 'Please complete all registration fields.'
    });
  }

  // Check password length
  if (password.length < 6) {
    return res.status(400).json({
      message: 'Password must be at least 6 characters.'
    });
  }

  const checkEmailSql = `
    SELECT userID FROM user WHERE email = ?
  `;

  db.query(checkEmailSql, [email.trim().toLowerCase()], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Database error.'
      });
    }

    if (results.length > 0) {
      return res.status(409).json({
        message: 'This email is already registered.'
      });
    }

    // Insert user information
    const userSql = `
      INSERT INTO user (username, email, phone, password, role)
      VALUES (?, ?, ?, ?, ?)
    `;

    const userValues = [
      username.trim(),
      email.trim().toLowerCase(),
      phone.trim(),
      password,
      'user'
    ];

    db.query(userSql, userValues, (err, userResult) => {
      if (err) {
        return res.status(500).json({
          message: 'Failed to register user.'
        });
      }

      // Get automatically generated userID
      const newUserID = userResult.insertId;

      // Insert vehicle information
      const vehicleSql = `
        INSERT INTO vehicle
        (userID, vehicle_type, plate_number, status)
        VALUES (?, ?, ?, ?)
      `;

      const vehicleValues = [
        newUserID,
        vehicle_type,
        plate_number.trim().toUpperCase(),
        'Active'
      ];

      db.query(vehicleSql, vehicleValues, (err, vehicleResult) => {
        if (err) {
          return res.status(500).json({
            message: 'User registered, but vehicle registration failed.'
          });
        }

        res.status(201).json({
          message: 'Registration successful!',
          userID: newUserID,
          vehicleID: vehicleResult.insertId
        });
      });
    });
  });
});

// Login  
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      message: 'Email and password are required.'
    });
  }

  const sql = `
    SELECT userID, username, email, phone, password, role
    FROM user
    WHERE email = ?
  `;

  db.query(sql, [email], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Database error.'
      });
    }

    if (results.length === 0) {
      return res.status(401).json({
        message: 'No account found with this email.'
      });
    }

    const user = results[0];

    if (user.password !== password) {
      return res.status(401).json({
        message: 'Incorrect email or password.'
      });
    }

    delete user.password;

    res.json({
      message: 'Login successful!',
      user: user
    });
  });
});

// trip history page 
// 1. Get all trips for a specific user
app.get('/trips/:userID', (req, res) => {
  const { userID } = req.params;

  const sql = `
    SELECT
      tripID,
      userID,
      vehicleID,
      COALESCE(tripTitle, CONCAT('Trip #', tripID)) AS tripTitle,
      startTime,
      endTime,
      durationSeconds,
      totalAlerts,
      tripStatus,
      videoURL,
      videoStartTime,
      createdAt,
      updatedAt
    FROM trip_session
    WHERE userID = ?
    ORDER BY startTime DESC
  `;

  db.query(sql, [userID], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Failed to fetch trips.',
        error: err.message
      });
    }

    res.json(results);
  });
});

//2. Create a new trip record
app.post('/trips', (req, res) => {
  const {
    userID,
    startTime,
    endTime,
    durationSeconds,
    totalAlerts,
    tripStatus
  } = req.body;

  if (!userID || !startTime || !endTime) {
    return res.status(400).json({
      message: 'userID, startTime, and endTime are required.'
    });
  }

  const getVehicleSql = `
    SELECT vehicleID
    FROM vehicle
    WHERE userID = ?
    LIMIT 1
  `;

  db.query(getVehicleSql, [userID], (err, vehicleResults) => {
    if (err) {
      return res.status(500).json({
        message: 'Database error looking up vehicle.',
        error: err.message
      });
    }

    const vehicleID =
      vehicleResults.length > 0 ? vehicleResults[0].vehicleID : null;

    const insertSql = `
      INSERT INTO trip_session
        (
          userID,
          vehicleID,
          startTime,
          endTime,
          durationSeconds,
          totalAlerts,
          tripStatus,
          createdAt,
          updatedAt
        )
      VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
    `;

    const values = [
      userID,
      vehicleID,
      startTime,
      endTime,
      durationSeconds || 0,
      totalAlerts || 0,
      tripStatus || 'Completed'
    ];

    db.query(insertSql, values, (insertErr, result) => {
      if (insertErr) {
        return res.status(500).json({
          message: 'Failed to create trip.',
          error: insertErr.message
        });
      }

      res.status(201).json({
        message: 'Trip created successfully!',
        tripID: result.insertId
      });
    });
  });
});

function formatMySQLDateTime(dateString) {
  return new Date(dateString)
    .toISOString()
    .slice(0, 19)
    .replace('T', ' ');
}

//3. Update an existing trip record
// UPDATE: EDIT TRIP TITLE ONLY
app.put('/trips/:tripID/title', (req, res) => {
  const { tripID } = req.params;
  const { tripTitle } = req.body;

  // Validate title
  if (!tripTitle || !tripTitle.trim()) {
    return res.status(400).json({
      message: 'Trip title cannot be empty.'
    });
  }

  if (tripTitle.trim().length > 100) {
    return res.status(400).json({
      message: 'Trip title cannot exceed 100 characters.'
    });
  }

  const sql = `
    UPDATE trip_session
    SET
      tripTitle = ?,
      updatedAt = NOW()
    WHERE tripID = ?
  `;

  const values = [
    tripTitle.trim(),
    tripID
  ];

  console.log('UPDATE TRIP TITLE:', values);

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('UPDATE TRIP TITLE ERROR:', err);

      return res.status(500).json({
        message: 'Failed to update trip title.',
        error: err.message
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Trip not found.'
      });
    }

    res.json({
      message: 'Trip title updated successfully!'
    });
  });
});

//4. Delete a trip record
app.delete('/trips/:tripID', (req, res) => {
  const { tripID } = req.params;

  const sql = `
    DELETE FROM trip_session
    WHERE tripID = ?
  `;

  db.query(sql, [tripID], (err, result) => {
    if (err) {
      return res.status(500).json({
        message: 'Failed to delete trip.',
        error: err.message
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        message: 'Trip not found.'
      });
    }

    res.json({
      message: 'Trip deleted successfully!'
    });
  });
});

//alert events for a specific trip
app.get('/trips/:tripID/alerts', (req, res) => {
    const { tripID } = req.params;

    const sql = `
        SELECT
            a.alertID,
            a.tripID,
            a.logID,
            a.alertType,
            a.drowsinessLevel,
            a.message,
            a.alertTime,
            a.alertStatus,
            e.eyeState,
            e.confidence,
            e.closureDuration,
            e.timestamp AS detectionTimestamp
        FROM alert_notification AS a
        LEFT JOIN eye_state_log AS e
            ON a.logID = e.logID
        WHERE a.tripID = ?
        ORDER BY a.alertTime ASC
    `;

    db.query(sql, [tripID], (err, results) => {
        if (err) {
            console.error('GET TRIP ALERTS ERROR:', err);

            return res.status(500).json({
                message: 'Failed to fetch trip alerts.',
                error: err.message
            });
        }

        res.status(200).json(results);
    });
});

//video URL and start time for a specific trip
app.get('/trips/:tripID/video', (req, res) => {
  const { tripID } = req.params;

  const sql = `
    SELECT
      tripID,
      videoURL,
      videoStartTime
    FROM trip_session
    WHERE tripID = ?
    LIMIT 1
  `;

  db.query(sql, [tripID], (err, results) => {
    if (err) {
      return res.status(500).json({
        message: 'Failed to fetch trip video.',
        error: err.message
      });
    }

    if (results.length === 0) {
      return res.status(404).json({
        message: 'Trip not found.'
      });
    }

    res.json({
      videoURL: results[0].videoURL,
      videoStartTime: results[0].videoStartTime
    });
  });
});

// Profile data and the driver's linked vehicles.
app.get('/users/:userID/profile', async (req, res) => {
  const userID = Number(req.params.userID);

  try {
    const [users] = await dbAsync.execute(
      `SELECT userID, username, email, phone, role, createdAt
       FROM user WHERE userID = ?`,
      [userID]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    const [vehicles] = await dbAsync.execute(
      `SELECT vehicleID, userID, vehicle_type, plate_number, status
       FROM vehicle WHERE userID = ?
       ORDER BY CASE WHEN LOWER(status) = 'active' THEN 0 ELSE 1 END, vehicleID`,
      [userID]
    );

    res.json({ user: users[0], vehicles });
  } catch (err) {
    console.error('GET PROFILE ERROR:', err);
    res.status(500).json({ message: 'Failed to load profile.' });
  }
});

// Update the driver's saved profile and the selected vehicle details.
app.put('/users/:userID/profile', async (req, res) => {
  const userID = Number(req.params.userID);
  const { username, email, phone, vehicleID, vehicleType, plateNumber } = req.body;

  if (!username?.trim() || !email?.trim()) {
    return res.status(400).json({ message: 'Name and email are required.' });
  }

  try {
    const [users] = await dbAsync.execute(
      'SELECT userID FROM user WHERE userID = ?',
      [userID]
    );
    if (users.length === 0) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    if (vehicleID != null) {
      const [vehicles] = await dbAsync.execute(
        'SELECT vehicleID FROM vehicle WHERE vehicleID = ? AND userID = ?',
        [vehicleID, userID]
      );
      if (vehicles.length === 0) {
        return res.status(404).json({ message: 'Vehicle not found.' });
      }
    }

    await dbAsync.beginTransaction();
    await dbAsync.execute(
      'UPDATE user SET username = ?, email = ?, phone = ? WHERE userID = ?',
      [username.trim(), email.trim().toLowerCase(), (phone || '').trim(), userID]
    );

    if (vehicleID != null) {
      await dbAsync.execute(
        `UPDATE vehicle SET vehicle_type = ?, plate_number = ?
         WHERE vehicleID = ? AND userID = ?`,
        [vehicleType || '', (plateNumber || '').trim().toUpperCase(), vehicleID, userID]
      );
    }

    await dbAsync.commit();
    res.json({ message: 'Profile updated successfully.' });
  } catch (err) {
    try { await dbAsync.rollback(); } catch (_) {}
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'That email address is already in use.' });
    }
    console.error('UPDATE PROFILE ERROR:', err);
    res.status(500).json({ message: 'Failed to update profile.' });
  }
});

// Mark one of the driver's own vehicles as active.
app.put('/users/:userID/vehicles/:vehicleID/active', async (req, res) => {
  const userID = Number(req.params.userID);
  const vehicleID = Number(req.params.vehicleID);

  try {
    const [vehicles] = await dbAsync.execute(
      'SELECT vehicleID FROM vehicle WHERE vehicleID = ? AND userID = ?',
      [vehicleID, userID]
    );
    if (vehicles.length === 0) {
      return res.status(404).json({ message: 'Vehicle not found.' });
    }

    await dbAsync.beginTransaction();
    await dbAsync.execute(
      "UPDATE vehicle SET status = 'Inactive' WHERE userID = ?",
      [userID]
    );
    await dbAsync.execute(
      "UPDATE vehicle SET status = 'Active' WHERE vehicleID = ? AND userID = ?",
      [vehicleID, userID]
    );
    await dbAsync.commit();
    res.json({ message: 'Active vehicle updated.' });
  } catch (err) {
    try { await dbAsync.rollback(); } catch (_) {}
    console.error('ACTIVATE VEHICLE ERROR:', err);
    res.status(500).json({ message: 'Failed to update active vehicle.' });
  }
});

// Seven-day report data, calculated only from this driver's stored rows.
app.get('/reports/:userID', async (req, res) => {
  const userID = Number(req.params.userID);
  const reportPeriod = (column) =>
    `${column} >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
     AND ${column} < DATE_ADD(CURDATE(), INTERVAL 1 DAY)`;

  try {
    const [tripRows] = await dbAsync.execute(
      `SELECT COUNT(*) AS totalTrips,
              COALESCE(AVG(CASE WHEN durationSeconds > 0 THEN durationSeconds END), 0) AS averageTripSeconds
       FROM trip_session
       WHERE userID = ? AND tripStatus = 'Completed'
         AND ${reportPeriod('startTime')}`,
      [userID]
    );

    const [alertRows] = await dbAsync.execute(
      `SELECT COUNT(*) AS totalAlerts
       FROM alert_notification a
       JOIN trip_session t ON t.tripID = a.tripID
       WHERE t.userID = ? AND ${reportPeriod('a.alertTime')}`,
      [userID]
    );

    const [dailyAlerts] = await dbAsync.execute(
      `SELECT DATE_FORMAT(a.alertTime, '%Y-%m-%d') AS day, COUNT(*) AS count
       FROM alert_notification a
       JOIN trip_session t ON t.tripID = a.tripID
       WHERE t.userID = ? AND ${reportPeriod('a.alertTime')}
       GROUP BY DATE_FORMAT(a.alertTime, '%Y-%m-%d') ORDER BY day`,
      [userID]
    );

    const [eyeStates] = await dbAsync.execute(
      `SELECT e.eyeState, COUNT(*) AS count
       FROM eye_state_log e
       JOIN trip_session t ON t.tripID = e.tripID
       WHERE t.userID = ? AND ${reportPeriod('e.timestamp')}
       GROUP BY e.eyeState`,
      [userID]
    );

    res.json({
      totalTrips: Number(tripRows[0].totalTrips),
      totalAlerts: Number(alertRows[0].totalAlerts),
      averageTripSeconds: Number(tripRows[0].averageTripSeconds),
      dailyAlerts: dailyAlerts.map((row) => ({
        day: row.day,
        count: Number(row.count)
      })),
      eyeStates: eyeStates.map((row) => ({
        state: row.eyeState,
        count: Number(row.count)
      }))
    });
  } catch (err) {
    console.error('GET REPORT ERROR:', err);
    res.status(500).json({ message: 'Failed to load report.' });
  }
});

// Delete the account only after the driver confirms their password.
app.delete('/users/:userID', async (req, res) => {
  const userID = Number(req.params.userID);
  const { password } = req.body;

  if (!password) {
    return res.status(400).json({ message: 'Password confirmation is required.' });
  }

  try {
    const [users] = await dbAsync.execute(
      'SELECT password FROM user WHERE userID = ?',
      [userID]
    );
    if (users.length === 0) {
      return res.status(404).json({ message: 'Account not found.' });
    }
    if (users[0].password !== password) {
      return res.status(401).json({ message: 'The password is incorrect.' });
    }

    await dbAsync.beginTransaction();
    await dbAsync.execute('DELETE FROM vehicle WHERE userID = ?', [userID]);
    await dbAsync.execute('DELETE FROM user WHERE userID = ?', [userID]);
    await dbAsync.commit();
    res.json({ message: 'Account and linked data deleted.' });
  } catch (err) {
    try { await dbAsync.rollback(); } catch (_) {}
    console.error('DELETE ACCOUNT ERROR:', err);
    res.status(500).json({ message: 'Failed to delete account.' });
  }
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});
