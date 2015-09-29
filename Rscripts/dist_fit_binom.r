library(knitr)

binom.fit = function(n, size, prob, noise.sd, show.table=TRUE, show.plot=TRUE) {

  ## generate random data from a binomial distrbution
  ## n = number of items tested
  ## size = number of trials per test
  ## prob = probability of failure
  dt = rbinom(n = n, size = size, prob = prob)
  ## add some noise to the distribution for more realistic data
  dt = round(dt * rnorm(n, mean = 1, sd = noise.sd))
  dt = data.frame(table(dt))
  colnames(dt) = c("trials", "results")
  dt$trials = as.numeric(dt$trials)-1  ## r oddity

  ## calculate the MLE
  mle = sum(dt$trials * dt$results) / sum(max(dt$trials) * dt$results)

  ## create a binomial model with the estimated mle and trials
  dt$mdl.p = round(dbinom(x = 0:(max(dt$trials)), size = max(dt$trials), prob = mle), 5)

  ## calculate expected results using the model probabilities
  dt$mdl.results = round(with(dt, mdl.p * sum(dt$results)), 2)

  ## mdl.results cant have less than 1 for any trial, check and correct
  dt.compressed = dt[which(dt$mdl.results > 1), ]

  ########################################################################
  ## This section cleans up the tails where there are not enough
  ## observations to get a good fit

  ## sum all rows where the expected results is less than 1
  ## and where trials are greater than the max trial of dt.compressed
  dt.results =
    sum(dt[which(dt$mdl.results < 1 &
                   dt$trials > max(dt.compressed$trials)), "results"])
  dt.mdl.p =
    sum(dt[which(dt$mdl.results < 1 &
                   dt$trials > max(dt.compressed$trials)), "mdl.p"])
  dt.mdl.results =
    sum(dt[which(dt$mdl.results < 1 &
                   dt$trials > max(dt.compressed$trials)), "mdl.results"])

  ## combined the summed observations with the last row in the results table
  dt.compressed[nrow(dt.compressed), "results"] =
    sum(dt.compressed[nrow(dt.compressed), "results"], dt.results)

  dt.compressed[nrow(dt.compressed), "mdl.p"] =
    sum(dt.compressed[nrow(dt.compressed), "mdl.p"], dt.mdl.p)

  dt.compressed[nrow(dt.compressed), "mdl.results"] =
    sum(dt.compressed[nrow(dt.compressed), "mdl.results"], dt.mdl.results)

  ## sum all rows where the expected results is less than 1
  ## and where trials are less than the minimum trial of dt.compressed
  dt.results =
    sum(dt[which(dt$mdl.results < 1 &
                   dt$trials < min(dt.compressed$trials)), "results"])
  dt.mdl.p =
    sum(dt[which(dt$mdl.results < 1 &
                   dt$trials < min(dt.compressed$trials)), "mdl.p"])
  dt.mdl.results =
    sum(dt[which(dt$mdl.results < 1 &
                   dt$trials < min(dt.compressed$trials)), "mdl.results"])

  ## combined the summed observations with the last row in the results table
  dt.compressed[1, "results"] =
    sum(dt.compressed[1, "results"], dt.results)

  dt.compressed[1, "mdl.p"] =
    sum(dt.compressed[1, "mdl.p"], dt.mdl.p)

  dt.compressed[1, "mdl.results"] =
    sum(dt.compressed[1, "mdl.results"], dt.mdl.results)

  ## replace original table with compressed table
  dt = dt.compressed

  ## clean up unneeded objects
  rm(dt.results, dt.mdl.p, dt.mdl.results, dt.compressed)

  ##########################################################################

  ## calculate Chi-square GOF statistic
  dt$ch.gof = round(with(dt, (results - mdl.results)^2 / mdl.results), 4)

  ## add up all of the statistics and calculate the model fit
  ch.p.value = round(1 - pchisq(q = sum(dt$ch.gof), df = max(dt$trials)),4)

  ch.conclusion =
    if (ch.p.value < .01)
      paste("Chi-squared P-value:", ch.p.value, ", unacceptable fit") else
        if(ch.p.value < .05)
          paste("Chi-squared P-value:", ch.p.value, ", poor fit") else
            if(ch.p.value < .15)
              paste("Chi-squared P-value:", ch.p.value, ", acceptable fit") else
                if(ch.p.value < .25)
                  paste("Chi-squared P-value:", ch.p.value, ", good fit") else
                    paste("Chi-squared P-value:", ch.p.value, ", excellent fit")

  ## formatting the output table
  results =
    kable(dt,
          format = "pandoc",
          row.names = FALSE,
          col.names = c("Trials", "Results", "Mdl Prob", "Mdl Results",
                        "CH GOF"),
          digits = 2,
          caption = paste("Model Statistics: \n",
                          "MLE:", round(mle, 4),
                          "\n", ch.conclusion))

  ## if statement to control the output
  if(show.plot == TRUE & show.table == TRUE) {
    ## generate plot
    par(xpd = TRUE)
    plot(x = NULL, y = NULL,
         xlim = c(0, max(dt$trials)),
         ylim = c(0, max(dt$results, dt$mdl.results)),
         xlab = "Trials", ylab = "Results",
         main = "Binomial Model")
    legend("topright", c("Experiment", "Model"),
           col = c("blue", "red"),
           pch = 19, bty = "n")
    points(x = dt$trials, y = dt$results,
           col = "blue", pch = 19, type = "b")
    points(x = dt$trials, y = dt$mdl.results,
           col = "red", pch = 19, type = "b")

    return(results)

  } else if(show.plot == TRUE & show.table == FALSE)  {
    par(xpd = TRUE)
    plot(x = NULL, y = NULL,
         xlim = c(0, max(dt$trials)),
         ylim = c(0, max(dt$results, dt$mdl.results)),
         xlab = "Trials", ylab = "Results",
         main = "Binomial Model")
    legend("topright", c("Experiment", "Model"),
           col = c("blue", "red"),
           pch = 19, bty = "n")
    points(x = dt$trials, y = dt$results,
           col = "blue", pch = 19, type = "b")
    points(x = dt$trials, y = dt$mdl.results,
           col = "red", pch = 19, type = "b")
  } else {
    return(results)
  }

}





