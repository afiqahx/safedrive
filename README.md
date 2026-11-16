## SafeDrive - Project Setup Guide ##

# 1. Requirements

Install the following software before starting:

- Git
- Flutter 
- Dart 
- Android Studio
- Visual Studio Code (optional)
- Node.js and npm – To run the backend server and install dependencies.
- MySQL Workbench – To connect to and manage the shared MySQL database.
- MySQL Server – Required only if running a local MySQL database.

Check your installations:
>git --version
>flutter --version
>dart --version
>node --version
>npm --version

# 2. Clone Repository

Clone the GitHub repository:https://github.com/afiqahx/safedrive.git

Before starting development, make sure you "pull" to have the latest project updates

# 3. Setup Flutter
>cd safedrive
>flutter pub get (Install all required Flutter dependencies)
>flutter devices (Check whether Flutter can detect your development devices, if you are using an Android emulator, open Android Studio and start your emulator.)
>flutter run (To run the application)

# 4. Setup Backend
>cd backend
>npm install (Install all required Node.js dependencies)
This will install the packages listed in `package.json`, such as:
- Express – To create the REST API.
- MySQL2 – To connect Node.js with MySQL.
- CORS – To allow API requests from different origins.
- Dotenv – To manage environment variables.

**Environment Configuration**
Create a .env file inside the backend folder using the provided .env.example.

Example:
.env
DB_HOST=YOUR_DATABASE_HOST
DB_USER=YOUR_ASSIGNED_USERNAME
DB_PASSWORD=YOUR_ASSIGNED_PASSWORD
DB_NAME=safedrive
DB_PORT=3307
PORT=3000

Replace the placeholder values with the database connection details provided by the project administrator.

Each team member must configure their own .env file using their assigned MySQL username and password.

**Important:**
- Do not upload .env to GitHub.
- Do not share database passwords in the group repository.
- Do not change the shared database host or database name.
- Make sure .env is included in .gitignore.

# 5. Run Backend
>cd safedrive_backend
>node server.js

If the backend starts successfully, it should display a message indicating that the server is running on port 3000.
Example:
SafeDrive API is running on port 3000

# 6. Run Flutter Application (run in different terminal)
>cd safedrive
>flutter run

# 7. Database
**Database Connection Using MySQL Workbench**

1. Open MySQL Workbench.
2. Create a new connection.
3. Enter the database host, port, username and password provided.
4. Click Test Connection.
5. Connect to the shared MySQL server.
6. Execute the following query:

sql query :
USE safedrive;

SHOW TABLES; 

SELECT * FROM user;
SELECT * FROM vehicle;
SELECT * FROM trip_session;
SELECT * FROM eye_state_log;
SELECT * FROM alert_notification;

# 8. Development Workflow
Step 1 : Update the Backend API (server.js)
1. Open the backend folder.
2. Open server.js.
3. Add or update the required API endpoints for your module.
4. Make sure the SQL queries use the correct database table and column names.

Step 2 : Update the API Service (api_service.dart)
1. Open api_service.dart.
2. Add the required API functions for your module.
3. Make sure the API URL matches the endpoint defined in server.js.

Step 3 : Create / Update the flutter UI 
Once the backend and API service are ready, proceed with the frontend development.(main.dart, home.dart, etc..)