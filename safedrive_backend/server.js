const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();

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

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});
