# PWNCLOUDOS Docker - GUI-Enabled Container with VNC

A lightweight, containerized version of PWNCLOUDOS with full GUI support via VNC and noVNC web interface.

## 🚀 Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/pwnedlabs/pwncloudos.git
cd pwncloudos

# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f
```

### Using Docker CLI

```bash
# Build the image
docker build -t pwncloudos:latest .

# Run the container
docker run -d \
  --name pwncloudos \
  -p 5901:5901 \
  -p 6080:6080 \
  --shm-size=2g \
  pwncloudos:latest
```

## 🌐 Accessing the Desktop

Once the container is running, you can access the PWNCLOUDOS desktop in two ways:

### Option 1: Web Browser (noVNC) - Easiest

1. Open your web browser
2. Navigate to: **http://localhost:6080/vnc.html**
3. Click "Connect"
4. Enter password: `pwnedlabs`
5. You're in! 🎉

### Option 2: VNC Client - Better Performance

1. Download a VNC client:
   - **Windows/Mac/Linux**: [TigerVNC Viewer](https://tigervnc.org/)
   - **macOS**: [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
   - **Linux**: `sudo apt install tigervnc-viewer` or `sudo dnf install tigervnc`

2. Connect to: `localhost:5901`
3. Enter password: `pwnedlabs`

## 📦 What's Included

The Docker image includes all PWNCLOUDOS tools organized under `/opt/`:

### Cloud Security Tools

- **AWS Tools** (`/opt/aws_tools/`): Pacu, PMapper, IAMGraph, etc.
- **Azure Tools** (`/opt/azure_tools/`): AzureHound, ROADtools, o365spray, etc.
- **GCP Tools** (`/opt/gcp_tools/`): gcp_scanner, workspace-enum, etc.
- **Multi-Cloud** (`/opt/multi_cloud_tools/`): Prowler, ScoutSuite, CloudFox, etc.

### Additional Tools

- **PowerShell Tools** (`/opt/ps_tools/`): AADInternals, GraphRunner, MFASweep, etc.
- **Code Scanning** (`/opt/code_scanning/`): TruffleHog, git-secrets
- **Cracking Tools** (`/opt/cracking_tools/`): John the Ripper, HashCat

### Cloud SDKs

- AWS CLI v2
- Azure CLI
- Google Cloud SDK (gcloud)

### Desktop Environment

- **WM**: XFCE4 (lightweight and responsive)
- **Browsers**: Chromium, Firefox ESR
- **Terminal**: XFCE4 Terminal with Zsh and PowerShell
- **Shells**: Zsh with Oh My Zsh, PowerShell
- **Utilities**: Flameshot (screenshots), tmux, htop, and more

## 🔧 Configuration

### Environment Variables

Customize the container behavior with environment variables:

```bash
docker run -d \
  --name pwncloudos \
  -e VNC_PASSWORD=mypassword \
  -e VNC_RESOLUTION=1920x1080 \
  -e TZ=America/New_York \
  -p 5901:5901 \
  -p 6080:6080 \
  --shm-size=2g \
  pwncloudos:latest
```

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `pwnedlabs` | VNC connection password |
| `VNC_RESOLUTION` | `1920x1080` | Desktop resolution |
| `TZ` | `UTC` | Timezone |
| `DISPLAY` | `:1` | X11 display number |

### Persistent Storage

Use volumes to persist your work across container restarts:

```yaml
volumes:
  - pwncloudos-home:/home/pwncloudos
  - pwncloudos-aws:/home/pwncloudos/.aws
  - pwncloudos-azure:/home/pwncloudos/.azure
  - pwncloudos-gcp:/home/pwncloudos/.config/gcloud
```

Or mount a local directory:

```bash
docker run -d \
  --name pwncloudos \
  -v $(pwd)/workspace:/home/pwncloudos/workspace \
  -p 5901:5901 \
  -p 6080:6080 \
  pwncloudos:latest
```

### Resource Limits

Adjust CPU and memory based on your system:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 6G
    reservations:
      cpus: '2'
      memory: 4G
```

## 🛠️ Common Tasks

### Managing the Container

```bash
# Start the container
docker-compose up -d

# Stop the container
docker-compose down

# Restart the container
docker-compose restart

# View logs
docker-compose logs -f

# Execute commands in the container
docker-compose exec pwncloudos zsh

# Access as root
docker-compose exec -u root pwncloudos bash
```

### Updating the Image

```bash
# Pull latest code
git pull

# Rebuild the image
docker-compose build --no-cache

# Restart with new image
docker-compose up -d
```

### Backing Up Your Work

```bash
# Export volumes
docker run --rm \
  -v pwncloudos-home:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/pwncloudos-backup.tar.gz /data

# Import volumes
docker run --rm \
  -v pwncloudos-home:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/pwncloudos-backup.tar.gz -C /
```

## 📊 Image Size Comparison

| Distribution | Size | GUI | Access Method |
|--------------|------|-----|---------------|
| VM Image (.ova) | ~10-20 GB | ✅ Full XFCE | Local hypervisor |
| Docker (this) | ~2-4 GB* | ✅ VNC/Web | Container |
| Headless Docker | ~1-2 GB | ❌ | CLI only |

*Final size depends on layer caching and optimization during build.

## 🔒 Security Considerations

### Running Security Tools

Some tools require elevated privileges:

```yaml
# Add specific capabilities instead of privileged mode
cap_add:
  - NET_ADMIN
  - NET_RAW
```

### Network Isolation

For testing in isolated environments:

```bash
# Create isolated network
docker network create --internal pwncloud-isolated

# Run container in isolated network
docker run -d \
  --name pwncloudos \
  --network pwncloud-isolated \
  pwncloudos:latest
```

### Secrets Management

**DO NOT** include credentials in the image. Use:

1. **Environment variables** for temporary credentials
2. **Docker secrets** for sensitive data
3. **Volume mounts** for credential files

```bash
# Mount AWS credentials
docker run -d \
  -v ~/.aws:/home/pwncloudos/.aws:ro \
  pwncloudos:latest
```

## 🐛 Troubleshooting

### VNC Server Won't Start

```bash
# Check logs
docker logs pwncloudos

# Restart the container
docker restart pwncloudos
```

### Black Screen in VNC

1. Wait 30-60 seconds for XFCE to fully load
2. Try refreshing the browser
3. Reconnect with your VNC client

### Out of Memory

Increase shared memory size:

```bash
docker run -d --shm-size=4g pwncloudos:latest
```

### Permission Issues

```bash
# Fix ownership inside container
docker exec -u root pwncloudos chown -R pwncloudos:pwncloudos /home/pwncloudos
```

### Browser Crashes

Browsers need more shared memory:

```bash
# Increase to 2GB or more
docker run -d --shm-size=2g pwncloudos:latest
```

## 🔄 Build Optimization

### Multi-Stage Build

The Dockerfile uses multi-stage builds to compile Go tools separately, reducing final image size.

### Layer Caching

To maximize build cache efficiency:

```bash
# Clean build (no cache)
docker-compose build --no-cache

# Use cache (faster)
docker-compose build
```

### BuildKit

Enable Docker BuildKit for faster builds:

```bash
DOCKER_BUILDKIT=1 docker-compose build
```

## 📚 Advanced Usage

### Custom Tool Installation

Add your own tools by creating a custom Dockerfile:

```dockerfile
FROM pwncloudos:latest

USER pwncloudos
RUN git clone https://github.com/example/tool /opt/custom_tools/tool
```

### Multiple Instances

Run multiple isolated instances:

```bash
# Instance 1
docker run -d --name pwncloud-aws -p 5901:5901 -p 6080:6080 pwncloudos:latest

# Instance 2
docker run -d --name pwncloud-azure -p 5902:5901 -p 6081:6080 pwncloudos:latest

# Instance 3
docker run -d --name pwncloud-gcp -p 5903:5901 -p 6082:6080 pwncloudos:latest
```

### CI/CD Integration

Use in your CI/CD pipelines:

```yaml
# Example GitLab CI
test:
  image: pwncloudos:latest
  script:
    - prowler aws --profile testing
    - scoutsuite run --provider azure
```

## 🎯 Use Cases

### Penetration Testing

```bash
# Start container with network access
docker run -d \
  --name pentest \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -p 5901:5901 \
  pwncloudos:latest
```

### Cloud Security Auditing

```bash
# Mount cloud credentials
docker run -d \
  -v ~/.aws:/home/pwncloudos/.aws:ro \
  -v ~/.azure:/home/pwncloudos/.azure:ro \
  -v ~/.config/gcloud:/home/pwncloudos/.config/gcloud:ro \
  pwncloudos:latest
```

### Training/Education

```bash
# Spin up instances for students
for i in {1..10}; do
  docker run -d \
    --name student-$i \
    -p $((5900+i)):5901 \
    -p $((6080+i)):6080 \
    pwncloudos:latest
done
```

## 🤝 Contributing

Found ways to optimize the Docker image further? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Make your improvements
4. Test thoroughly
5. Submit a pull request

## 📝 License

MIT License - See [LICENSE](LICENSE) file

## 🔗 Related Links

- [Main Documentation](https://pwncloudos.readthedocs.io/)
- [GitHub Repository](https://github.com/pwnedlabs/pwncloudos)
- [Discord Community](https://discord.gg/mPfCrnZdXR)
- [Pwned Labs](https://pwnedlabs.io)

---

**Built with ❤️ by the Pwned Labs team**
