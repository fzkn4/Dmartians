# DigitalOcean App Platform Deployment Guide  
_D'MARSIANS Taekwondo System (native PHP via Docker)_

---

## 1. Overview

This document describes how to deploy the existing PHP + MySQL application to **DigitalOcean App Platform** using the provided `Dockerfile`. App Platform will run the web tier while a separate **Managed MySQL** database stores persistent data. Special handling is required for uploaded assets and JSON-based storage because App Platform containers have ephemeral file systems.

---

## 2. Prerequisites

- DigitalOcean account with billing enabled.
- GitHub/GitLab repo containing this project (Dockerfile at repository root).
- Domain name (optional, but needed for custom URL + HTTPS).
- Access to SMTP2GO credentials (already referenced in `config.php`).
- Understanding of App Platform limitations:
  - Containers rebuild on every deploy; local files are not persistent.
  - Horizontal scaling spawns multiple stateless containers.

---

## 3. Target Architecture

```
┌────────────────────────────┐        ┌──────────────────────────┐
│ DigitalOcean App Platform  │        │ DigitalOcean Managed DB  │
│ Service (Docker image)     │<──────>│ MySQL 8                  │
│ - PHP 8.2 + Apache         │        │ - capstone_db            │
│ - Serves HTTP/HTTPS        │        │ - capstone_user          │
└────────────────────────────┘        └──────────────────────────┘
          │
          ├─ (Optional) DigitalOcean Spaces bucket for uploads
          │
          └─ Clients via HTTPS (App Platform-managed load balancer)
```

---

## 4. Prepare the Repository

1. **Clean secrets**  
   Ensure no real passwords remain in `config.php`. The file already supports environment variables, so redeploys rely on runtime configuration.

2. **Commit the repo**  
   ```
   git add .
   git commit -m "Prep for App Platform"
   git push origin main
   ```

3. **(Recommended) Add `.env.example`**  
   Document required env vars (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `SMTP2GO_*`, `ADMIN_BCC_EMAIL`).

---

## 5. Provision Managed MySQL

1. In the DigitalOcean dashboard: **Databases → Create → MySQL**.
2. Choose region closest to your users and minimum size (1 GB / 1 vCPU is fine for small loads).
3. Once provisioned, note:
   - **HOST** (e.g., `db-mysql-nyc3-12345-do-user-123456-0.b.db.ondigitalocean.com`)
   - **PORT** (default `25060` for TLS, `3306` for plain)
   - **DATABASE NAME** (`capstone_db`)
   - **USER** (`capstone_user`)
   - **PASSWORD**
4. Add a trusted source: **App Platform** will automatically connect from the same region, but for local imports you may need to allow your IP temporarily.
5. Import schema/data:
   ```bash
   mysql -h HOST -u capstone_user -p -P 25060 --ssl-mode=REQUIRED capstone_db < Database/db.sql
   ```

---

## 6. Create App Platform Service

1. **Apps → Create App**.
2. Select your **GitHub/GitLab repo** and branch.
3. Detection:
   - Choose the **root directory** (contains `Dockerfile`).
   - Runtime = Dockerfile-based service.
4. **Build & Run commands**  
   - Leave blank (App Platform uses `docker build` and `CMD` from Dockerfile).
5. **HTTP Port**  
   - Set to `80` (Apache listens on 80 inside the container).
6. **Scaling**  
   - Start with 1 container (`Basic` tier). Enable autoscaling later if needed (note: uploads need shared storage before scaling out).
7. **Environment Variables** (Service-level):
   | Key | Value | Notes |
   | --- | --- | --- |
   | `DB_HOST` | `<managed-db-host>` | Use TLS hostname |
   | `DB_PORT` | `25060` (or `3306`) | Optional (default 3306) |
   | `DB_USER` | `capstone_user` | |
   | `DB_PASSWORD` | `********` | Use App Platform secret |
   | `DB_NAME` | `capstone_db` | |
   | `SMTP2GO_API_KEY` | `api-...` | |
   | `SMTP2GO_SENDER_EMAIL` | `...@...` | |
   | `SMTP2GO_SENDER_NAME` | `D'Marsians Taekwondo Gym` | |
   | `ADMIN_BCC_EMAIL` | `helmandacuma5@gmail.com` | |
   - Mark sensitive values as **Encrypt**.
8. **Deploy**  
   Click “Next” → “Create Resources”. App Platform will build the Docker image and run it.

---

## 7. Handling File Uploads & JSON Storage

### 7.1 Images (`uploads/posts/`)

- **Current behavior**: Files saved under `uploads/posts/` inside the container.  
- **Problem**: App Platform containers cannot persist writes across deploys/restarts, and instances do not share disks.

**Options:**
1. **DigitalOcean Spaces (recommended)**  
   - Create an S3-compatible bucket.  
   - Replace `move_uploaded_file()` destination with Spaces upload via SDK or cURL.  
   - Store resulting public URL in MySQL.  
   - Keeps uploads persistent and globally accessible.
2. **App Platform Persistent Volumes (beta/limits)**  
   - Attach a volume to `/var/www/html/uploads`.  
   - Works only in regions/plans where volumes are supported; still single-instance storage.
3. **Accept ephemeral storage (not production-safe)**  
   - Works for demos, but images vanish on deploy or scale events.

### 7.2 `trial_requests.json`

- Replace JSON storage with a **database table** (`trial_requests`) and migrate read/write logic accordingly.  
- If left as-is, pending trial data will be wiped whenever the container restarts.

---

## 8. Domain & HTTPS

1. **Connect a domain** in App Platform → “Domains & Certificates”.
2. Add `example.com` (and `www`). App Platform supplies DNS records; update them at your registrar.
3. Once DNS propagates, App Platform issues free Let’s Encrypt certificates automatically.
4. Force HTTPS inside App settings (“Enforce HTTPS”).

---

## 9. Environment-Specific Tuning

- **PHP settings**: Already defined in Dockerfile image. For overrides, bake a `php.ini` into the image or mount via build step.
- **Error logging**: In production, set `display_errors=Off` (already done in `index.php`; confirm global settings).
- **CRON jobs / background tasks**: App Platform services do not support cron; use DigitalOcean Functions or a Worker service if needed.

---

## 10. Post-Deployment Checks

1. **App logs** (App Platform dashboard → Logs)  
   - Confirm Apache started successfully.  
   - Watch for PHP warnings or DB connection issues.
2. **Database connectivity**  
   - Use admin login; check that student lists load (queries hitting `capstone_db`).
3. **Uploads**  
   - Test creating a post with an image. Verify where the file lands (Spaces/volume).  
   - If using ephemeral storage, document the limitation for stakeholders.
4. **Emails**  
   - Trigger OTP/reset flows to ensure SMTP2GO credentials work from the cloud environment.

---

## 11. Deploying Updates

1. Commit and push changes to the tracked branch.
2. App Platform auto-deploys or you can trigger manually (“Deploy” button).
3. For schema changes: run migrations manually against Managed MySQL before or after deploy.

---

## 12. Cost & Limitations Summary

- **App Platform Basic service**: starts ~$5–$12/month per container.
- **Managed MySQL**: starts ~$15/month.
- **Spaces (if used)**: $5/month + bandwidth.
- **Limitations**:
  - No native cron jobs.
  - Local disk is ephemeral; design for externalized storage.
  - Build + deploy times tied to Docker image size (optimize assets if necessary).

---

## 13. Checklist

- [ ] Managed MySQL provisioned & schema imported.
- [ ] Environment variables configured (DB + SMTP).
- [ ] Upload strategy decided (Spaces or volume).  
      - [ ] Application updated to write to chosen storage.
- [ ] `trial_requests` JSON logic migrated to DB (or accepted as ephemeral).
- [ ] Domain mapped + HTTPS enabled.
- [ ] Admin login verified post-deploy.
- [ ] File uploads tested from App Platform environment.
- [ ] Logs monitored for errors after deployment.

---

## 14. References

- [DigitalOcean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [DigitalOcean Managed Databases](https://www.digitalocean.com/products/managed-databases/)
- [DigitalOcean Spaces](https://www.digitalocean.com/products/spaces/)
- [App Platform Persistent Storage](https://docs.digitalocean.com/products/app-platform/how-to/use-persistent-storage/) (if available in your region)

---

**Need help migrating uploads or JSON data to MySQL/Spaces?**  
Document the desired approach (Spaces vs DB) and update the PHP handlers accordingly before production launch.







