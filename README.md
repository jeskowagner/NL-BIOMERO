# <img src="https://raw.githubusercontent.com/NL-BioImaging/OMERO.biomero/refs/tags/v1.2.1/webapp/src/img/biomero-logo.svg" alt="BIOMERO" height="28" style="height:28px; width:auto; vertical-align:middle;"> Containerized OMERO with BIOMERO

NL‑BIOMERO delivers a full containerized stack to run **OMERO** together with the **<img src="https://raw.githubusercontent.com/NL-BioImaging/OMERO.biomero/refs/tags/v1.2.1/webapp/src/img/biomero-logo.svg" alt="BIOMERO" height="16" style="height:16px; width:auto; vertical-align:middle;"> BIOMERO 2.0** framework. It provides Docker/Podman configurations and Compose files to deploy OMERO + BIOMERO subsystems (importer, analyzer, OMERO.web plugin, databases, and auxiliary services) — the recommended starting point for a FAIR‑oriented bioimaging setup.

BIOMERO 2.0 is described in our preprint: [“BIOMERO 2.0: end-to-end FAIR infrastructure for bioimaging data import, analysis, and provenance”](https://arxiv.org/abs/2511.13611). It transforms OMERO into a provenance‑aware, FAIR (findable, accessible, interoperable, reusable) platform by combining:
- containerized data import and preprocessing (importer subsystem),  
- containerized or HPC‑based analysis workflows (analyzer subsystem),  
- metadata enrichment, versioning, and provenance tracking,  
- integrated workflow monitoring and dashboards.

🎥 **Introduction video**  
👉 https://nl-bioimaging.github.io/NL-BIOMERO/latest/overview.html

Using NL‑BIOMERO yields a unified environment where image data import, preprocessing, analysis, and provenance tracking are managed end-to-end — from raw data to processed results — in a reproducible, shareable, FAIR‑compliant infrastructure.

## Architecture Overview

![BIOMERO 2.0 Architecture](docs/BIOMERO2_overview.png)

*BIOMERO 2.0 architecture showing the integration of containerized analysis workflows (BIOMERO 1.0), preprocessing workflows (BIOMERO 2.0), and the unified OMERO.biomero web interface with OMERO.forms for metadata collection.*

It uses Docker Compose to setup an OMERO grid on one computer with a server, web, processor, and a BIOMERO processor, importer and database.
If you want to experiment with a local HPC cluster, an example Docker Compose setup is hosted <a href="https://github.com/NL-BioImaging/NL-BIOMERO-Local-Slurm" target="_blank" rel="noopener noreferrer">here</a>.

This is an adaptation of OME's <a href="https://github.com/ome/docker-example-omero-grid" target="_blank" rel="noopener noreferrer">OMERO.server grid and OMERO.web (docker-compose)</a> / <a href="http://www.openmicroscopy.org/site/support/omero5/sysadmins/grid.html#nodes-on-multiple-hosts" target="_blank" rel="noopener noreferrer">OMERO.server components on multiple nodes using OMERO.grid</a>.

- OMERO.server listens on ports `4063` and `4064`  
- OMERO.web listens on port `4080` (http://localhost:4080/)  

> ⚠️ **Warning:** This setup is mainly intended for demonstration or development purposes. For professional deployments, refer to the documented deployment scenarios in our documentation and see the [deployment scenarios](./deployment_scenarios) folder. We **strongly discourage** running Slurm inside Docker Compose for production; connect BIOMERO to a real HPC cluster to ensure stability, full feature support, and performance.

---

## 🚀 Platform-Specific Deployment

### Windows (Docker Desktop)
Follow the **Quickstart** section below for Windows deployment with Docker Desktop.

### Ubuntu/Linux
For Ubuntu/Linux deployments (with SSL support), see our dedicated guide:
📖 **[Ubuntu/Linux Deployment Guide](https://nl-bioimaging.github.io/NL-BIOMERO/latest/sysadmin/linux-deployment.html)**

---

## Quickstart (Windows)

**Note**: This quickstart is based on Windows Docker Desktop and uses `host.docker.internal` to communicate between local clusters. Linux users should refer to the [Ubuntu/Linux guide](https://nl-bioimaging.github.io/NL-BIOMERO/latest/sysadmin/linux-deployment.html).

### 0. Prerequisites

- Docker Desktop
- Git for Windows
- a SSH keypair (@ ~/.ssh/id_rsa)
- Powershell

Then do all these steps in Powershell:

### 1. Clone and Setup
Clone this repository locally:

```bash
git clone --recursive https://github.com/NL-BioImaging/NL-BIOMERO.git
cd NL-BIOMERO
```

### 2. Configure Environment
First, customize your environment file `.env`:

```bash
# Edit .env with your secure passwords and configuration
# Edit biomeroworker/slurm-config.ini if you need different BIOMERO settings
# Toggle UI components (both default to TRUE):
# IMPORTER_ENABLED=TRUE   # Enables the BIOMERO.importer UI module
# ANALYZER_ENABLED=TRUE   # Enables the BIOMERO.analyzer UI module
# Set either to FALSE to hide that module from OMERO.web without removing containers
```

### 3. Setup Slurm Connection (Optional)

For local testing, deploy a containerized Slurm cluster alongside NL-BIOMERO
using [jeskowagner/slurm-docker-cluster](https://github.com/jeskowagner/slurm-docker-cluster)
(Slurm 25.x, BIOMERO-compatible).

#### 3a. Generate the biomeroworker keypair

The biomeroworker container reaches slurmctld with its own keypair under
`./biomeroworker-ssh/` (gitignored — each deployment generates its own):

```bash
mkdir -p biomeroworker-ssh
ssh-keygen -t rsa -b 4096 -f biomeroworker-ssh/id_rsa -N "" -C biomeroworker
touch biomeroworker-ssh/known_hosts
# uid 1000 = omero-server inside the biomeroworker container
sudo chown -R 1000:1000 biomeroworker-ssh/
```

Then create `biomeroworker-ssh/config` with:

```
Host localslurm
    HostName slurmctld
    User slurm
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
```

#### 3b. Bring up the Slurm cluster

The slurm stack attaches to NL-BIOMERO's `nl-biomero_omero` Docker network.
If you haven't deployed NL-BIOMERO yet (step 5 below), create the network
first so the slurm stack has somewhere to attach:

```bash
docker network create nl-biomero_omero
```

Clone the fork:

```bash
cd ..
git clone -b nl-biomero https://github.com/jeskowagner/slurm-docker-cluster
cd slurm-docker-cluster
```

**CPU-only:** create `.env` with

```ini
COMPOSE_PROJECT_NAME=slurm-docker-cluster
SLURM_VERSION=25.11.4
SSH_ENABLE=true
SSH_AUTHORIZED_KEYS=../NL-BIOMERO/biomeroworker-ssh/id_rsa.pub
SSH_PORT=2222
CPU_WORKER_COUNT=2
```

then build the biomero compatibility layer and bring up the stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.biomero.yml build slurmdbd
docker compose -f docker-compose.yml -f docker-compose.biomero.yml up -d
cd ../NL-BIOMERO
```

**With NVIDIA GPU:** requires
[nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
on the host. Add three more lines to `.env`:

```ini
COMPOSE_PROJECT_NAME=slurm-docker-cluster
SLURM_VERSION=25.11.4
SSH_ENABLE=true
SSH_AUTHORIZED_KEYS=../NL-BIOMERO/biomeroworker-ssh/id_rsa.pub
SSH_PORT=2222
CPU_WORKER_COUNT=2
GPU_ENABLE=true
GPU_WORKER_COUNT=1
UPSTREAM_TAG=25.11.4-gpu-2.3.1
```

build and bring up with the `gpu` profile (the build step pulls the GPU base
image automatically via `UPSTREAM_TAG`):

```bash
docker compose -f docker-compose.yml -f docker-compose.biomero.yml build slurmdbd
docker compose -f docker-compose.yml -f docker-compose.biomero.yml --profile gpu up -d
cd ../NL-BIOMERO
```

Workers register dynamically: `c1`, `c2`, ... on the `cpu` partition (default),
`g1`, `g2`, ... on the `gpu` partition.

> [!NOTE]
> The previous documented option,
> [NL-BIOMERO-Local-Slurm](https://github.com/NL-BioImaging/NL-BIOMERO-Local-Slurm)
> (Slurm 21.08), still runs but is no longer the recommended path for new
> deployments.

### 4. Configure SSH Access

Verify the slurm cluster accepts the biomeroworker pubkey from the host
(via slurmctld's published SSH port 2222):

```bash
ssh -i biomeroworker-ssh/id_rsa -p 2222 -o StrictHostKeyChecking=no slurm@localhost
exit
```

Inside the biomeroworker container, biomero reaches slurmctld with the
alias `localslurm` (already configured in `biomeroworker-ssh/config` from
step 3a). It resolves to `slurmctld:22` over Docker's `nl-biomero_omero`
network — no host-side `~/.ssh/config` edit needed. You can confirm
after step 5 with:

```bash
docker compose exec biomeroworker ssh localslurm hostname
# expect: slurmctld
```

If the host-side test fails, double-check that
`slurm-docker-cluster/.env`'s `SSH_AUTHORIZED_KEYS` points at the same
pubkey you generated in step 3a, and that the slurm stack came up
cleanly:

```bash
docker exec slurmctld sinfo
```

Optional: if you want a host-side `ssh localslurm` alias for manual
testing, see `ssh.config.example` and append it to your `~/.ssh/config`.

### 5. Deploy NL-BIOMERO
Launch the full stack:

```bash
# For development (with local builds)
docker-compose build --no-cache
# Then run in the background
docker-compose up -d

# OR 

# For production (using pre-built images)
docker-compose --env-file .\.env -f .\deployment_scenarios\docker-compose-from-dockerhub.yml pull
# wait ~10 min for download
docker-compose --env-file .\.env -f .\deployment_scenarios\docker-compose-from-dockerhub.yml up -d
```

Monitor the deployment:

```bash
docker-compose logs -f

# OR

docker-compose --env-file .\.env -f .\deployment_scenarios\docker-compose-from-dockerhub.yml logs -f
```
Exit w/ CTRL + C

Verify the alias works:

```bash
# go inside your biomeroworker container:
docker-compose exec biomeroworker bash
# OR
docker-compose --env-file .\.env -f .\deployment_scenarios\docker-compose-from-dockerhub.yml exec biomeroworker bash 

# from inside your biomeroworker container:
ssh localslurm
exit
exit
```

### 6. Access the Interfaces
- **OMERO.web**: http://localhost:4080
  - **Login**: `root` / `omero` (change default password)
- **Metabase**: http://localhost:3000  
  - **Login**: `admin@biomero.com` / `b1omero` (change default password)

If you disabled modules via `IMPORTER_ENABLED=FALSE` or `ANALYZER_ENABLED=FALSE`, the corresponding UI tabs/panels won't appear.


---

## 📊 Data Import

To get started with data:

1. **Web Import**: Use the Importer tab in OMERO.biomero at http://localhost:4080/omero_biomero/biomero/
2. **OMERO.insight**: Download the <a href="https://downloads.openmicroscopy.org/help/pdfs/getting-started-5.pdf" target="_blank" rel="noopener noreferrer">desktop client</a>
   - Connect to `localhost:4063`
   - Login as `root` / `omero`

---

## <img src="https://raw.githubusercontent.com/NL-BioImaging/OMERO.biomero/refs/tags/v1.2.1/webapp/src/img/biomero-logo.svg" alt="BIOMERO" height="22" style="height:22px; width:auto; vertical-align:middle;"> BIOMERO - BioImage Analysis

Checkout the <a href="https://nl-bioimaging.github.io/biomero/" target="_blank" rel="noopener noreferrer">BIOMERO documentation</a> for detailed usage instructions.

### Quick Workflow Example:

1. **Initialize Environment**:
   - Run script: `biomero` > `admin` > `SLURM Init environment...`
   - ☕ Grab coffee (10+ min download time for a few workflow containers)

2. **Run Analysis**:
   - Select your image/dataset
   - Run script: `biomero` > `__workflows` >`SLURM Run Workflow...`
   - Configure import: Change `Import into NEW Dataset` → `hello_world`
   - Select workflow: e.g., `cellpose`
   - Set parameters: nucleus channel, GPU settings, etc.

OR

2. **OMERO.biomero Analyzer UI**:
   - Use the Analyzer tab at http://localhost:4080/omero_biomero/biomero/?tab=biomero
   - Select your workflow: e.g., `Cellpose`
   - Add Dataset, select the image(s) you want to segment
   - Fill in the workflow parameters in tab 2, e.g. nuclei channel 3
   - Select desired output target, e.g. Select Dataset `hello_world` again (don't forget to press ENTER if you're typing it); and Run!
   - Track your workflow status at the `Status` tab


3. **View Results**:
   - Refresh OMERO `Explore` tab (in the Data tab; http://localhost:4080/webclient/)
   - Find your `hello_world` dataset with generated masks

---

## 🛠️ Container Management

### Basic Operations
```bash
# Stop the cluster
docker-compose down

# Remove with volumes (⚠️ deletes data)
docker-compose down --volumes

# Rebuild single container
docker-compose up -d --build --force-recreate <container-name>

# Access container shell
docker-compose exec <container-name> bash
```

### Useful Container Names
- `omeroserver` - OMERO server
- `omeroweb` - Web interface  
- `biomeroworker` - BIOMERO processor
- `metabase` - Analytics dashboard

---

## 🔧 Configuration

### Slurm Connection Requirements
See <a href="https://nl-bioimaging.github.io/biomero/" target="_blank" rel="noopener noreferrer">BIOMERO documentation</a> for comprehensive setup details.

**Essential Components**:
- **SSH Configuration**: Headless SSH to Slurm server
  - Server IP/hostname
  - SSH port (usually `22`)
  - Username and SSH keys
  - Alias configuration in `~/.ssh/config`
- **Slurm Configuration**: Edit `biomeroworker/slurm-config.ini`
  - SSH alias (e.g., `localslurm`)
  - Storage paths: `slurm_data_path`, `slurm_images_path`, `slurm_script_path`

### Linux Considerations
- SSH permissions: `chmod -R 777 ~/.ssh` before deployment
- Use `postgres:16-alpine` for better compatibility
- See [Ubuntu/Linux guide](https://nl-bioimaging.github.io/NL-BIOMERO/latest/sysadmin/linux-deployment.html) for detailed instructions

---

## 🎨 Frontend Customizations
This deployment includes several UI enhancements:

- **🧩 OMERO.biomero Plugin**: Unified BIOMERO.importer and BIOMERO.analyzer tabs
- **📝 OMERO.forms**: Create custom metadata forms for users to fill in
- **🔘 Better Buttons**: Improved some button design and accessibility
- **🎭 Pretty Login**: Minor enhanced login page aesthetics


The previous codename "CANVAS" has been replaced by the official name OMERO.biomero.



### Custom Institution Branding

By default, BIOMERO 2.0 uses NL-BioImaging branding. To customize:

**Change banner logo:** Mount your logo over the banner image
```yml
- "./your-logo.png:/opt/omero/web/venv3/lib/python3.12/site-packages/omeroweb/webclient/static/webclient/image/login_page_images/nl-bioimaging-banner.png:ro"
```

**Change footer logo:** Mount your logo over the footer image  
```yml
- "./your-logo.png:/opt/omero/web/venv3/lib/python3.12/site-packages/omeroweb/webclient/static/webclient/image/login_page_images/NL-BIoImaging-logo.jpg:ro"
```

**Change footer text/colors/design:** Create custom `login.html` template with inline CSS and mount it
```yml
- "./custom-login.html:/opt/omero/web/venv3/lib/python3.12/site-packages/omeroweb/webclient/templates/webclient/login.html:ro"
```

Restart container after changes: `docker-compose down omeroweb && docker-compose up -d omeroweb`

See `web/local_omeroweb_edits/pretty_login/login-amsterdamumc.html` for complete template example.

More details in [web/README.md](web/README.md).

---

## � Development

### Building Documentation

#### Quick local preview (working directory)

To preview your **uncommitted changes** instantly:

```powershell
cd "NL-BIOMERO\docs"
.\venv\Scripts\sphinx-build.exe -b html . _build_local
```

Then open `docs/_build_local/sysadmin/omero-biomero-admin.html` (or any page) in a browser.

> **Note**: `sphinx-multiversion` builds from **git commits only** — it will not pick up
> uncommitted edits. Always use `sphinx-build` for a quick preview while authoring.

#### Full versioned build (all tags + branches)

Once your changes are committed, rebuild the complete versioned site:

```powershell
cd "NL-BIOMERO\docs"
Remove-Item -Recurse -Force _build -ErrorAction SilentlyContinue
.\venv\Scripts\sphinx-multiversion.exe . _build
Copy-Item assets/gh-pages-redirect.html _build/index.html
$latestTag = (git tag -l "v*.*.*" | Where-Object { $_ -match "^v[0-9]+\.[0-9]+\.[0-9]+$" } | Sort-Object {[version]($_ -replace '^v','')} -Descending | Select-Object -First 1)
if ($latestTag) { Copy-Item "_build/$latestTag" "_build/latest" -Recurse; Write-Host "Created latest directory pointing to $latestTag" }
```

This builds all tagged versions and branches, then creates a `latest/` directory pointing to the newest release tag.

---

## 📚� Additional Resources

- 📖 **[Ubuntu/Linux Deployment](https://nl-bioimaging.github.io/NL-BIOMERO/latest/sysadmin/linux-deployment.html)** - Production deployment guide
- 🧬 **<a href="https://nl-bioimaging.github.io/biomero/" target="_blank" rel="noopener noreferrer">BIOMERO Documentation</a>** - Analysis workflows
- 🏗️ **<a href="https://github.com/NL-BioImaging/NL-BIOMERO-Local-Slurm" target="_blank" rel="noopener noreferrer">Local Slurm Cluster</a>** - Testing environment
- 🔬 **<a href="https://omero.readthedocs.io/" target="_blank" rel="noopener noreferrer">OMERO Documentation</a>** - Core platform docs

---

## 🤝 Support

- **Issues**: <a href="https://github.com/NL-BioImaging/NL-BIOMERO/issues" target="_blank" rel="noopener noreferrer">GitHub Issues</a>
- **Discussions**: <a href="https://forum.image.sc/" target="_blank" rel="noopener noreferrer">image.sc</a> (tag #biomero)
- **Contact**: cellularimaging /at/ amsterdamumc.nl

Happy imaging! 🔬✨
