# Contributing to londonremembers

## Development Setup

This package uses Nix for reproducible development environments.

### Prerequisites

1. Install [Nix](https://nixos.org/download.html)
2. Clone the repository

### Getting Started

```bash
# Enter the Nix development environment
nix-shell

# Inside nix-shell, run R
R
```

### Development Workflow

All R commands should be run within the nix-shell:

```bash
# Generate documentation
nix-shell --run "Rscript -e 'roxygen2::roxygenise()'"

# Run tests
nix-shell --run "Rscript -e 'devtools::test()'"

# Run R CMD check
nix-shell --run "Rscript -e 'devtools::check()'"

# Build package
nix-shell --run "R CMD build ."

# Install locally
nix-shell --run "Rscript -e 'devtools::install()'"
```

### Code Style

- Follow standard R package conventions
- Use roxygen2 for documentation
- Write tests for new functions
- Ensure `R CMD check` passes with 0 errors, 0 warnings, 0 notes

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass
5. Update documentation
6. Submit a pull request

The GitHub Actions workflows will automatically:
- Run R CMD check on multiple platforms
- Calculate test coverage
- Build pkgdown documentation

### CI/CD Pipelines

Three workflows run automatically on push:

1. **R-CMD-check** - Tests package on Ubuntu and macOS
2. **test-coverage** - Calculates and reports code coverage
3. **pkgdown** - Builds and deploys package website

All workflows use the same `shell.nix` environment for reproducibility.

### Updating Dependencies

If you need to add R package dependencies:

1. Add to `DESCRIPTION` (Imports or Suggests)
2. Add to `shell.nix` (as `rPackages.<package>`)
3. Update documentation/imports as needed
4. Run `R CMD check` to verify

### Questions?

Open an issue on GitHub if you have questions or suggestions!
