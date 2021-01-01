# Hello World Example

A minimal project that uses GGM to add/update a file in every project of a gitlab group.

The following is output in the job logs from the minimal `gitlab-ci.yml` when run for the first time:

```
...
$ ggm
GGM::File(shared-files/hello.md) already up to date in Example GGM Project
Unprotect master in Example Project 1
Add commit with message: Created file: shared-files/hello.md
Re-protect master in Example Project 1
Unprotect master in Example Project 2
Add commit with message: Created file: shared-files/hello.md
Re-protect master in Example Project 2
...
Job succeeded
```

And subsequent runs (assuming no change to the file, the group, or it's projects) result in:

```
...
$ ggm
GGM::File(shared-files/hello.md) already up to date in Example GGM Project
GGM::File(shared-files/hello.md) already up to date in Example Project 1
GGM::File(shared-files/hello.md) already up to date in Example Project 2
...
Job succeeded
```