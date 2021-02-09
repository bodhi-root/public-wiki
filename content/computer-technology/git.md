---
title: Git
---

## Showing the Origin of a Repository
This is also a useful command if you forget where your original copy of the repository is:

```
git remote show origin
```

Run this from inside your local project folder to see where the master copy or origin resides.

## Basic Commands for Committing Changes

The following commands walk you through the basics of committing changes to git.

| Command | Description |
|---------|-------------|
| ```git add <path>``` | Adds files that have been modified to the list of files that will be saved in a commit. "git add *" will add all files. Other useful commands include:<br/>```git add -A``` Stages all changes to match the working directory. This captures all new files, modifications, and removals.<br/>```git add -u``` Stages all changes made to existing files. This capture modifications and removals, but not new files. |
| ```git commit -m "<msg>"``` | Commits all changes. The message is a text string to describe changes made in this commit. |
| ```git status``` | Print status. This shows lists of files that have been modified as well as those that are staged for commit. |
| ```git push``` | Push all changes from local repository to the master/origin repository |
| ```git pull``` | Update local repository from the master/origin repository |

## Switching Between Versions

The following commands are useful for viewing old versions and switching back to these versions if needed.

| Command | Description |
|---------|-------------|
| ```git log``` | Print a log of all changes on the current branch. This will list basic information about each version. |
| ```git show <hash>``` | Prints detailed information on the given version and changes from the previous version. You only need to specify the first few characters of the hash - just enough to uniquely identify it. |
|```git checkout <hash>``` | Checks out the version specified by the hash. This will update the working directory to match this version of the code. This is a historical snapshot only. You can't make changes unless you create a separate branch at this point using ```git checkout -b <new_branch>```. |

## Working with Branches

| Command | Description |
|---------|-------------|
| ```git branch``` | Print a list of all branches |
| ```git branch <branch>``` | Creates a new branch with the given name. This will not switch to the new branch unless you use the "-b" option. If you want to delete a branch use the "-d <branch>" option. |
| ```git checkout <branch>``` | Checkout the given branch. This will checkout the HEAD version of this branch. |

If you forget to start a new branch and instead start working on master (like I frequently seem to do), you can create a new branch with:

```
git checkout -b <branch>
```

All of your changes will still be there and ready to commit to the new branch.

## Other Commands

| Command | Description |
|---------|-------------|
| ```git checkout HEAD -- file.txt``` | If you want to discard your edits on a single file and update them instead to the HEAD this checkout command will let you do that. (The "--" argument says indicates that every argument after this one should be treated as a file name, no matter what it looks like or whether it looks like other arguments.) |
| ```git rm --cached file.txt``` | Removes the file from version control. The "--cached" flag indicates that this should only update the index and not remove the actual file from the working directory. A recursive command (```git rm --cached -r target```) is useful if you forgot your '.gitignore' file and accidentally versioned the 'target' file. I've only done that about 10 times now... |

## Common Errors and Fixes

### "git pull" fails because of local changes

Sometimes "git pull" will fail with the following message:

```
Your local changes to the following files would be overwritten by merge:
```

This is because you have changed files locally that someone else has also changed in the remote repository.  As mentioned here, you have 3 options:

#### 1. Commit the change using

```
git commit -m "My message"
```

#### 2. Stash it.

Stashing acts as a stack, where you can push changes, and you pop them in reverse order.  To stash type:

```
git stash
```

Do the merge, and then pull the stash:

```
git stash pop
```

#### 3. Discard the local changes

You can discard all changes with either:

```
git reset --hard
```

or:

```
git checkout -t -f remote/branch
```

You can also just discard changes on a specific file with:

```
git checkout <filename>
```

### Accidentally committed to "master" (locally)

If you accidentally committed to the wrong branch, it's very easy to rollback those changes and apply them elsewhere.  If you only did one commit, you just run the following:

```
git reset HEAD~1
git checkout -b <branch>
```

The first command will undo your commit.  The files you changed will still be in their new form after running this command.  This means that you can just checkout a new branch, then add the changes there, and commit as usual.  Easy peesy!

## Migrating Repositories

If you want to migrate a repository, simply use the commands below:

```
git clone --mirror <url_of_old_repo>
cd <name_of_old_repo>
git remote add new-origin <url_of_new_repo>
git push new-origin --mirror
```

You can then drop the old remote and rename the new one to the default with:

```
git remote rm origin
git remote rename new-origin origin
```
