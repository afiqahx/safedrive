require('dotenv').config();

const mysql = require('mysql2');

const connection = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT
});

connection.connect((err) => {
  if (err) {
    console.error('MySQL connection failed:', err);
    return;
  }

  console.log('Connected to SafeDrive MySQL!');
});

module.exports = connection;
