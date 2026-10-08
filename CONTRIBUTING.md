# Contributing to Awesome Docker Compose

Thank you for considering contributing to the **Awesome Docker Compose** project! We welcome contributions of all kinds, including bug fixes, new features, documentation improvements, and more.

## How to Contribute

### 1. Fork the Repository
Start by forking the repository to your GitHub account. This allows you to make changes without affecting the original project.

### 2. Clone the Repository
Clone your forked repository to your local machine:
```sh
git clone https://github.com/your-username/awesome-docker-compose.git
```

### 3. Create a Branch
Create a new branch for your changes:
```sh
git checkout -b feature/your-feature-name
```

### 4. Make Changes
Make your changes to the codebase. Ensure your changes are well-documented and follow the project's coding standards.

### 5. Test Your Changes
If applicable, test your changes to ensure they work as expected. If you're adding a new Docker Compose configuration, verify that it runs without errors.

## Checklist for a new or changed project

CI enforces most of this on every pull request (`.github/workflows/ci.yml`):

- [ ] Directory `base/<name>/` or `stacks/<name>/` with `compose.yaml`, `.env.example` (if it has variables), `.gitignore` and `README.md`
- [ ] README has: services table, quick start, access URLs and default credentials, configuration table, notes
- [ ] Project is linked in the root `README.md` (CI fails otherwise)
- [ ] Image tags are pinned (avoid `latest` unless there is no alternative)
- [ ] Every long-running service has a healthcheck, and the tool it uses exists in the image (many images ship `curl` but not `wget`, or the other way round)
- [ ] `docker compose config -q` passes with and without `.env.example`
- [ ] Defaults are for local development only and say so; no real secrets
- [ ] You ran `scripts/smoke.sh <dir>` locally. If the project is lightweight, add it to the `smoke` matrix in `ci.yml`; if it needs lots of RAM or time, add it to `heavy-smoke.yml`
- [ ] For S3-compatible stores, `scripts/s3-smoke.py` passes against the endpoint
- [ ] Bind-mounted data directories are listed in the README (`mkdir -p ...`) and in `.gitignore`

### 6. Commit Your Changes
Commit your changes with a clear and concise commit message:
```sh
git add .
git commit -m "Add feature: your-feature-name"
```

### 7. Push to Your Fork
Push your changes to your forked repository:
```sh
git push origin feature/your-feature-name
```

### 8. Submit a Pull Request
Go to the original repository on GitHub and submit a pull request. Provide a detailed description of your changes and why they should be merged.

## Code of Conduct
Please review our [Code of Conduct](./CODE_OF_CONDUCT.md) before contributing. By participating, you agree to abide by its terms.

## Reporting Issues
If you encounter any issues or have suggestions for improvement, please open an issue in the repository. Provide as much detail as possible to help us address the problem.

## Need Help?
If you have any questions or need assistance, feel free to reach out by opening an issue or contacting the maintainers.

We appreciate your contributions and look forward to collaborating with you!
