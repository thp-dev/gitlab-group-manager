# Gitlab Group Manager

![CI](https://github.com/thp-dev/gitlab-group-manager/workflows/CI/badge.svg)

Apply files, settings and more to groups of Gitlab projects.

Current functionality is limited to committing files to groups of repos simultaneously.

## Getting Started

TODO

## Development

```
# Generate a gitlab personal access token with api permissions
export GITLAB_TOKEN=your-token

# Build and run container locally (token is passed in to the container)
docker-compose up -d

# Get a bash prompt in the container
docker-compose exec dev bash

# Install development and test gems
bundle config --delete without
bundle install

# Do development
rspec
rubocop

# etc...
```

## Contributing

TODO