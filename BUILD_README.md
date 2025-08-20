# Conda Package Automation

This directory contains automation scripts for building, converting, and publishing the `alpaca_kernel_2` conda package.

## Quick Start

```bash
# Make the script executable (if not already)
chmod +x build_and_publish.sh

# Run with default settings (builds for Python 3.10, uploads to nb_tudelft)
./build_and_publish.sh

# Run in dry-run mode to see what would happen
./build_and_publish.sh --dry-run

# Build for different Python version
./build_and_publish.sh --python-version 3.11

# Upload to different organization
./build_and_publish.sh --organization my-org --label dev
```

## Features

The `build_and_publish.sh` script provides a complete automation pipeline:

1. **Prerequisites Check**: Verifies conda, anaconda-client, and login status
2. **Package Building**: Creates both `.conda` and `.tar.bz2` formats
3. **Cross-Platform Conversion**: Generates packages for all supported platforms:
   - Linux: x86_64, i386, aarch64, armv6l, armv7l, ppc64, ppc64le, s390x
   - macOS: x86_64, arm64 (Apple Silicon)
   - Windows: x86, x86_64, arm64
4. **Upload**: Pushes all artifacts to Anaconda Cloud
5. **Verification**: Confirms successful upload and package availability

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--python-version VERSION` | Python version for build | `3.10` |
| `--organization ORG` | Anaconda organization | `nb_tudelft` |
| `--label LABEL` | Anaconda label/channel | `main` |
| `--skip-build` | Skip build step if artifacts exist | `false` |
| `--skip-convert` | Skip conversion step | `false` |
| `--skip-upload` | Skip upload step | `false` |
| `--dry-run` | Show commands without executing | `false` |
| `-h, --help` | Show help message | - |

## Prerequisites

Before running the script, ensure you have:

1. **Conda/Miniconda installed**
   ```bash
   # Check conda is available
   conda --version
   ```

2. **Anaconda client installed**
   ```bash
   # Install if not available
   conda install anaconda-client
   ```

3. **Logged in to Anaconda Cloud**
   ```bash
   # Login to your account
   anaconda login
   
   # Verify login
   anaconda whoami
   ```

4. **Proper permissions** to upload to the target organization (nb_tudelft)

## Usage Examples

### Basic Usage
```bash
# Complete build and publish workflow
./build_and_publish.sh
```

### Development Workflow
```bash
# Test what would happen without making changes
./build_and_publish.sh --dry-run

# Build only (no conversion or upload)
./build_and_publish.sh --skip-convert --skip-upload

# Convert and upload existing builds
./build_and_publish.sh --skip-build
```

### Different Configurations
```bash
# Build for Python 3.11
./build_and_publish.sh --python-version 3.11

# Upload to development channel
./build_and_publish.sh --label dev

# Upload to different organization
./build_and_publish.sh --organization my-personal-org
```

## Output Structure

The script generates the following structure:

```
alpaca_kernel_2/
├── build_and_publish.sh          # Main automation script
├── dist/
│   └── converted/                 # Cross-platform converted packages
│       ├── linux-64/
│       ├── linux-32/
│       ├── linux-aarch64/
│       ├── linux-armv6l/
│       ├── linux-armv7l/
│       ├── linux-ppc64/
│       ├── linux-ppc64le/
│       ├── linux-s390x/
│       ├── osx-64/
│       ├── osx-arm64/
│       ├── win-32/
│       ├── win-64/
│       └── win-arm64/
└── conda-bld/                    # Original conda build outputs
```

## Error Handling

The script includes comprehensive error handling:

- **Prerequisites**: Checks for required tools and authentication
- **Build errors**: Stops execution if build fails
- **Upload errors**: Uses `--skip-existing` to handle duplicate uploads
- **Validation**: Verifies package visibility on Anaconda Cloud

## Troubleshooting

### Common Issues

1. **"conda not found"**
   - Install Anaconda/Miniconda
   - Ensure conda is in your PATH

2. **"anaconda client not found"**
   ```bash
   conda install anaconda-client
   ```

3. **"Not logged in to Anaconda Cloud"**
   ```bash
   anaconda login
   ```

4. **"Permission denied" for organization**
   - Verify you have upload permissions to the target organization
   - Contact the organization admin to grant permissions

5. **"Package not found" after upload**
   - Wait a few minutes for Anaconda Cloud to update
   - Check the organization and label are correct

### Debug Mode

Run with verbose output to troubleshoot issues:
```bash
# Enable bash debug mode
bash -x ./build_and_publish.sh --dry-run
```

## Manual Steps (Alternative)

If you prefer to run steps manually:

```bash
# 1. Build packages
conda build . --python=3.10 --no-anaconda-upload --package-format tar.bz2
conda build . --python=3.10 --no-anaconda-upload --package-format conda

# 2. Convert for all platforms
mkdir -p dist/converted
conda convert $(conda info --base)/conda-bld/linux-64/alpaca_kernel_2-*-py310_0.tar.bz2 --platform all -o dist/converted

# 3. Upload to Anaconda Cloud
anaconda upload -u nb_tudelft -l main --skip-existing $(conda info --base)/conda-bld/linux-64/alpaca_kernel_2-*-py310_0.*
find dist/converted -name "*.tar.bz2" -exec anaconda upload -u nb_tudelft -l main --skip-existing {} \;

# 4. Verify upload
anaconda show nb_tudelft/alpaca_kernel_2
```

## Package Installation

After successful upload, users can install the package:

```bash
# Install from nb_tudelft organization
conda install -c nb_tudelft alpaca_kernel_2

# Install specific version
conda install -c nb_tudelft alpaca_kernel_2

# Install from specific label
conda install -c nb_tudelft/label/dev alpaca_kernel_2
```

## Next Steps

- Consider setting up CI/CD automation with GitHub Actions
- Add version bumping automation
- Implement testing before upload
- Add support for multiple Python versions in single run