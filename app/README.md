## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd lab-final-project
   ```

2. **Build and run with Docker Compose:**
   ```bash
   docker compose up -d --build
   ```

3. **Open your browser:**
   ```
   http://localhost:8080
   ```

## Customization

### Personalize Your Name

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file:**
   ```bash
   nano .env
   ```

3. **Update your name:**
   ```env
   USER_NAME=Your Name Here
   ```

4. **Rebuild and restart:**
   ```bash
   docker compose up -d --build
   ```

### Alternative: Set Name Directly

You can also set the name without creating a `.env` file:

```bash
USER_NAME="Jane Doe" docker compose up -d --build
```

Or modify `docker-compose.yml` directly:

```yaml
environment:
  - USER_NAME=Jane Doe
```
