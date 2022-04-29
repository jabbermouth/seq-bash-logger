# seq-bash-logger
A script to log to Seq from using a Bash script.

## Parameters
### `-l <level>`
`level` values are typically:
* Debug
* Information (default)
* Warning
* Error
* Fatal

### `-s <seq-server-url>`
This is the URL to send ingestion events to.  By default, they go to `http://host.docker.internal:5341/`.

### `-k <api-key>`
This is the API key to pass to Seq.

### `-t <title>`
This is a text string that appears at the top of the log.  It supports the insertion of entry properties so, for example, if there is a `MachineName` property, you could have a title of `Log event created on {MachineName}`.

### `-x <exception>`
The exceptopn details to log.

### `-f <filepath>`
As an alternative to sending the exception on the command line, a file can be used for the exception field.  This could be used if output was being redirected to a file. This is particular useful with multiline output.  For example:
```
ls -1 >> log.txt
```
Then send to Seq with:
```
bash logger.sh -f log.txt
```
