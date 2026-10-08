#!/usr/bin/env python3
"""Security / hygiene policy for the compose files (Trivy does not scan compose files).

Errors (fail CI): privileged containers, host network/pid/ipc, the Docker socket,
dangerous capabilities, a bind mount of the host root.
Warnings (printed, do not fail): seccomp/apparmor profiles disabled ("unconfined").

Exceptions: scripts/policy-exceptions.txt, one per line: "<project> <service> <rule>  # reason".
Usage: scripts/check-policy.py [project-dir ...]   (default: every project under base/ and stacks/)
"""
import glob, json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DANGEROUS_CAPS = {"ALL", "SYS_ADMIN", "SYS_PTRACE", "NET_ADMIN", "SYS_MODULE"}


def load_exceptions():
    ex = set()
    path = os.path.join(ROOT, "scripts", "policy-exceptions.txt")
    if os.path.exists(path):
        for line in open(path):
            line = line.split("#", 1)[0].strip()
            if line:
                ex.add(tuple(line.split()[:3]))
    return ex


def config(project):
    out = subprocess.run(
        ["docker", "compose", "--env-file", "/dev/null", "--profile", "*", "config", "--format", "json"],
        cwd=os.path.join(ROOT, project), capture_output=True, text=True)
    if out.returncode != 0:
        print(f"::error::{project}: docker compose config failed: {out.stderr.strip()[:200]}")
        sys.exit(2)
    return json.loads(out.stdout)


def main():
    projects = sys.argv[1:] or sorted(
        os.path.relpath(os.path.dirname(p), ROOT)
        for p in glob.glob(os.path.join(ROOT, "*", "*", "compose.yaml"))
        if os.path.relpath(p, ROOT).split(os.sep)[0] in ("base", "stacks"))
    exceptions = load_exceptions()
    errors = warnings = 0

    def report(level, project, svc, rule, msg):
        nonlocal errors, warnings
        if (project, svc, rule) in exceptions:
            return
        print(f"::{level} file={project}/compose.yaml::{svc}: {msg} [{rule}]")
        if level == "error":
            errors += 1
        else:
            warnings += 1

    for project in projects:
        for name, svc in config(project).get("services", {}).items():
            if svc.get("privileged"):
                report("error", project, name, "privileged", "privileged container")
            for key in ("network_mode", "pid", "ipc"):
                if svc.get(key) == "host":
                    report("error", project, name, f"host-{key}", f"{key}: host")
            for vol in svc.get("volumes", []):
                src = str(vol.get("source", ""))
                if src.endswith("docker.sock"):
                    report("error", project, name, "docker-socket", "mounts the Docker socket")
                if vol.get("type") == "bind" and src == "/":
                    report("error", project, name, "host-root", "bind-mounts the host root")
            caps = {c.upper() for c in svc.get("cap_add", [])}
            if caps & DANGEROUS_CAPS:
                report("error", project, name, "cap-add", f"dangerous capabilities {sorted(caps & DANGEROUS_CAPS)}")
            for opt in svc.get("security_opt", []):
                if "unconfined" in opt:
                    report("warning", project, name, "unconfined", f"security_opt {opt}")
    print(f"policy check: {len(projects)} projects, {errors} errors, {warnings} warnings")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
