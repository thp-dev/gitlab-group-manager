# Gitlab Group Manager

![CI](https://github.com/thp-dev/gitlab-group-manager/workflows/CI/badge.svg)

Keeping gitlab project settings consistent in an organisation can be challenging. Gitlab Group Manager gives teams the ability to define common settings and files across all the projects in a group. 
## Getting Started

GGM can be run from anywhere you can run docker, but it's well suited to being run in a gitlab CI job.

All you need is a `.ggm.yaml` config file, which identifies the group(s) to manage and the settings/files to apply to the projects in that group.

NOTE: See [examples/hello-world](examples/hello-world) for a complete example

### An example ggm config file

```
groups:
  - name: Example Group
    excluded_subgroups:
      - 'SubGroup 1'
    archived: false
    files: 
      - path: .gitlab/merge_request_templates/Default.md
        commit_suffix: ' [skip ci]'
    merge_request_approvals:
      approvals_before_merge: 3,
      disable_overriding_approvers_per_merge_request: true
```

### An example gitlab job

```
stages:
  - run-ggm

# Requires a CI/CD Variable (GITLAB_TOKEN) to be set
# Reads the config from the default location (.ggm.yaml)
manage-gitlab-group:
  stage: run-ggm
  image: thpdev/ggm:latest
  variables:
    DRY_RUN: true
  script: ggm
```

### Run the GGM container locally 

- NOTE: DRY_RUN enabled, so nothing destructive can happen

```
docker run -it --rm -v $(pwd):/usr/src/data -e GITLAB_TOKEN="your gitlab token" -e DRY_RUN=true thpdev/ggm:latest
```

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