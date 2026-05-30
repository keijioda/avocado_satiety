

# Function to search variables --------------------------------------------

search_var <- function(df, pattern, ...) {
  loc <- grep(pattern, names(df), ...)
  if (length(loc) == 0) warning("There are no such variables")
  else return(data.frame(loc = loc, varname = names(df)[loc]))
}


# Function to run LRT for each covariate ----------------------------------

lrt_each_covariate <- function(model) {
  
  # Extract components from the fitted model
  full_formula  <- formula(model)
  covariates    <- attr(terms(full_formula), "term.labels")
  random        <- model$modelStruct$reStruct
  correlation   <- model$modelStruct$corStruct
  data          <- model$data
  control       <- model$control
  
  # Refit full model with ML (override REML)
  full_model <- update(model, method = "ML")
  
  results <- lapply(covariates, function(covar) {
    
    # Drop one covariate from the formula
    reduced_vars <- setdiff(covariates, covar)
    
    if (length(reduced_vars) == 0) {
      reduced_fm <- formula(paste(deparse(full_formula[[2]]), "~ 1"))
    } else {
      reduced_fm <- formula(paste(deparse(full_formula[[2]]), "~", paste(reduced_vars, collapse = " + ")))
    }
    
    # Refit reduced model with ML using update()
    reduced_model <- update(full_model, fixed = reduced_fm)
    
    # LRT: chi-square statistic and df
    lr_stat <- 2 * (logLik(full_model) - logLik(reduced_model))
    df_diff <- attr(logLik(full_model), "df") - attr(logLik(reduced_model), "df")
    p_value <- pchisq(lr_stat, df = df_diff, lower.tail = FALSE)
    
    data.frame(
      covariate      = covar,
      logLik_full    = as.numeric(logLik(full_model)),
      logLik_reduced = as.numeric(logLik(reduced_model)),
      LR_stat        = as.numeric(lr_stat),
      df             = df_diff,
      p_value        = p_value
    )
  })
  
  # Combine results
  result_df <- do.call(rbind, results)
  rownames(result_df) <- NULL
  
  # Format p-value
  result_df$p_value <- format.pval(result_df$p_value, digits = 4, eps = 0.0001)
  
  result_df
}


# Function to format emmeans table ----------------------------------------

make_emmeans_tab <- function(emmeans_obj, pairs_obj, exponentiate = FALSE, digits = 2) {
  
  # Extract the first variable from the emmeans object
  group_var <- names(emmeans_obj@levels)[1]
  
  # Extract pairwise p-values
  pairs_df <- summary(pairs_obj) %>%
    as.data.frame() %>%
    select(meal_type, contrast, p.value) %>%
    mutate(p.value = format.pval(round(p.value, 4), digits = 4, eps = 0.0001, scientific = FALSE)) %>%
    pivot_wider(names_from = contrast, values_from = p.value) %>%
    rename(
      vs_no_avoc  = 2,  # "No avocado at all - <1 avocado"
      vs_no_avoc2 = 3,  # "No avocado at all - 1 whole avocado or more"
      vs_lt_1avoc = 4   # "<1 avocado - 1 whole avocado or more"
    )
  
  summary(emmeans_obj) %>%
    as.data.frame() %>%
    { if (exponentiate) mutate(., across(c(emmean, lower.CL, upper.CL), exp)) else . } %>%
    mutate(across(c(emmean, lower.CL, upper.CL), ~ round(., digits))) %>%
    select(-SE, -df) %>%
    mutate(
      meal_type = fct_relevel(
        meal_type,
        "Morning meal",
        "Morning snack",
        "Midday meal",
        "Midday snack",
        "Evening meal",
        "Late night snack"
      ),
      meal_or_snack = if_else(as.numeric(meal_type) %in% c(2, 4, 6), 1, 0),
      meal_or_snack = factor(meal_or_snack, labels = c("Meal", "Snack"))
    ) %>%
    arrange(meal_or_snack, meal_type) %>%
    left_join(
      pairs_df %>% select(meal_type, vs_no_avoc, vs_no_avoc2, vs_lt_1avoc),
      by = "meal_type"
    ) %>%
    mutate(
      grp = .data[[group_var]],
      vs_no_avoc = case_when(
        grp == levels(grp)[2] ~ vs_no_avoc,
        grp == levels(grp)[3] ~ vs_no_avoc2,
        TRUE ~ NA_character_
      ),
      vs_lt_1avoc = case_when(
        grp == levels(grp)[3] ~ vs_lt_1avoc,
        TRUE ~ NA_character_
      )
    ) %>%
    select(-vs_no_avoc2, -grp)
}
