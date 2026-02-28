# Redis Module

This module provisions a single Redis instance on OCI for WebSocket pub/sub between
multiple backend instances.

## Architecture

```
backend-1 ──┐
             ├──► Redis (pub/sub broker) ◄── shared channel
backend-2 ──┘
```

Both backend instances subscribe to the same Redis channel and relay messages to their
connected WebSocket clients, ensuring real-time messages sent to one backend instance
are delivered to clients connected to any backend instance.

## Backend Application Configuration

After `terraform apply`, retrieve the Redis private IP:

```bash
terraform output redis_private_ip
```

### docker-compose.prod.yml

Update the backend's `docker-compose.prod.yml` (deployed to `/opt/<app_name>/`) to pass
Redis config as environment variables to the Micronaut container:

```yaml
environment:
  - REDIS_HOST=<redis_private_ip>
  - REDIS_PORT=6379
  - REDIS_PASSWORD=<redis_password>
```

### Micronaut application.yml

```yaml
redis:
  uri: redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}
```

> **Note**: Redis uses password-only authentication (no username). The URI format
> `redis://:password@host:port` uses an empty username field before the colon, which
> is the standard way to specify a Redis AUTH password in a URI.

## Security Notes

- Redis port 6379 is **only** accessible within the private subnet CIDR — never from the public subnet or internet
- `redis_password` is marked `sensitive = true` and should be stored in `terraform.tfvars` (git-ignored)
- Redis requires `--requirepass` — unauthenticated access is disabled
- The instance has `assign_public_ip = false` — it is never directly reachable from the internet
