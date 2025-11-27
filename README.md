# Capstone - Martial Arts School Management System

A PHP-based web application for managing martial arts school operations including student enrollment, payments, and content management.

## 🐳 Docker Setup

This project is configured to run with Docker for easy development and deployment.

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Quick Start

1. **Clone the repository** (if not already done)

   ```bash
   git clone <your-repo-url>
   cd Capstone
   ```

2. **Start the application**

   ```bash
   docker-compose up -d
   ```

3. **Access the application**
   - **Main Website**: http://localhost:8080
   - **Admin Panel**: http://localhost:8080/admin_login.php
   - **phpMyAdmin**: http://localhost:8081

### Default Credentials

- **Username**: `admin`
- **Password**: `admin123`

### Services

- **PHP Application**: Port 8080
- **MySQL Database**: Port 3307
- **phpMyAdmin**: Port 8081

### Database Configuration

The application automatically connects to the MySQL database with these credentials:

- **Host**: `db` (Docker service name)
- **Database**: `capstone_db`
- **Username**: `capstone_user`
- **Password**: `capstone_password`

### File Uploads

The `uploads/` directory is mounted as a volume, so uploaded files persist between container restarts.

### Development

For development, the application files are mounted as volumes, so changes are reflected immediately without rebuilding the container.

### Stopping the Application

```bash
docker-compose down
```

To remove all data (including database):

```bash
docker-compose down -v
```

### Troubleshooting

1. **Port conflicts**: If ports 8080, 8081, or 3307 are already in use, modify the `docker-compose.yml` file
2. **Database connection issues**: Ensure the database service is fully started before accessing the application
3. **File permissions**: The container automatically sets proper permissions for the uploads directory

### Production Deployment

For production, consider:

- Using environment variables for sensitive data
- Setting up proper SSL certificates
- Configuring backup strategies for the database
- Using a production-ready web server configuration
