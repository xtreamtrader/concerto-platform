concerto.run = function(workingDir, client, sessionHash, maxIdleTime = NULL, maxExecTime = NULL, response = NULL, initialPort = NULL) {
    concerto$workingDir <<- workingDir
    concerto$client <<- client
    concerto$sessionHash <<- sessionHash
    concerto$sessionFile <<- paste0(concerto$workingDir,"session.Rs")
    concerto$initialPort <<- initialPort

    if(!is.null(maxIdleTime)) {
        concerto$maxIdleTime <<- maxIdleTime
    }
    if(!is.null(maxExecTime)) {
        concerto$maxExecTime <<- maxExecTime
    }

    concerto$connection <<- concerto5:::concerto.db.connect(concerto$connectionParams$driver, concerto$connectionParams$username, concerto$connectionParams$password, concerto$connectionParams$dbname, concerto$connectionParams$host, concerto$connectionParams$unix_socket, concerto$connectionParams$port)
    concerto["session"] <<- list(NULL)
    if(!is.null(concerto$sessionHash)) {
        concerto$session <<- as.list(concerto5:::concerto.session.get(concerto$sessionHash))
        concerto$session$previousStatus <<- concerto$session$status
        concerto$session$status <<- STATUS_RUNNING
        concerto$session$params <<- fromJSON(concerto$session$params)
        concerto$mainTest <<- list(id=concerto$session$test_id)
    }
    concerto$resuming <<- F

    tryCatch({
        setwd(concerto$workingDir)
        if(concerto$maxExecTime > 0) {
            setTimeLimit(elapsed=concerto$maxExecTime, transient=TRUE)
        }

        if(!is.null(concerto$session)) {
            testId = concerto$session["test_id"]
            params = concerto$session$params
            if(concerto$runnerType == RUNNER_SERIALIZED && concerto.session.unserialize(response)) {

                concerto$resuming <<- T
                concerto$resumeIndex <<- 0
                testId = concerto$flow[[1]]$id
                params = concerto$flow[[1]]$params
            }
            concerto.test.run(testId, params)
        }

        concerto5:::concerto.session.stop(STATUS_FINALIZED, RESPONSE_FINISHED)
    }, error = function(e) {
        concerto.log(e)
        if(!is.null(concerto$session)) { concerto$session$error <<- e }
        concerto5:::concerto.session.stop(STATUS_ERROR, RESPONSE_ERROR)
    })
}