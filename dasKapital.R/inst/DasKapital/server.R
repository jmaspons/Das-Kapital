server <- function(input, output, session) {
  
  ## DK1 secció 5 ----
  
  sim_prod <- reactive({
    # req()
    escenari <- expand.grid(
      jornada = seq(input$jornada[1], input$jornada[2], length.out = 3),
      intensitat = seq(input$intensitat[1], input$intensitat[2], length.out = 5),
      productivitat = seq(input$productivitat[1], input$productivitat[2], length.out = 2),
      preu_treball = input$preu_treball
    )
    
    resultat <- treball_plusvalua(
      jornada = escenari$jornada, intensitat = escenari$intensitat,
      productivitat = escenari$productivitat, preu_treball = escenari$preu_treball
    )
    resultat <- cbind(escenari, resultat)
  }, label = "DK1 secció 5")
  
  # DEBUG: input <- list(jornada = 8:16, intensitat = seq(0.75, 1.5, by = .25), productivitat = seq(1, 1.5, by = .25), preu_treball = 5)
  output$k1_s5_grafic_p <- renderPlotly({
    s <- sim_prod()
    gg <- ggplot(s, mapping = aes(x = treball_necessari, y = plusvalua, color = intensitat)) +
      geom_hline(aes(yintercept = preu_treball), color = "red", linewidth = 1, show.legend = TRUE) +
      geom_point() +
      scale_color_viridis_c() +
      facet_grid(productivitat ~ jornada, labeller = label_both)
    
    config(plotly::ggplotly(gg), displayModeBar = FALSE)
  })
  
  output$k1_s5_grafic_taxaExplotacio <- renderPlotly({
    s <- sim_prod()
    gg <- ggplot(s, mapping = aes(x = jornada, y = plusvalua / treball_necessari, color = intensitat, group = intensitat)) +
      geom_point() +
      geom_line() +
      facet_wrap(~productivitat) +
      scale_color_viridis_c()

    config(plotly::ggplotly(gg), displayModeBar = FALSE)
  })
  
  output$k1_s5_grafic_taxaExplotacioAbsoluta <- renderPlotly({
    s <- sim_prod()
    gg <- ggplot(s, mapping = aes(x = jornada, y = plusvalua / valor, color = intensitat, group = intensitat)) +
      geom_point() +
      geom_line() +
      facet_wrap(~productivitat) +
      scale_color_viridis_c()
    
    config(plotly::ggplotly(gg), displayModeBar = FALSE)
  })

  
  ## DK3 secció 1 ----
  
  output$k3_s1_grafic_b_c <- renderPlot({
    c <- 50:500
    b <- taxa_benefici(p = input$p, c = c, v = input$v)
    p <- taxa_plusvalua(p = input$p, v = input$v)
    plot(c, b, xlab = "Capital constant (c)", ylab = "Taxa de benefici (b')", type = "l", col = "green")
    abline(a = p, b = 0, "red")
  })
  output$k3_s1_grafic_b_v <- renderPlot({
    v <- 50:500
    b <- taxa_benefici(p = input$p, c = input$c, v = v)
    p <- taxa_plusvalua(p = input$p, v = input$v)
    plot(v, b, xlab = "Capital variable (v)", ylab = "Taxa de benefici (b')", type = "l", col = "red")
  })
  output$k3_s1_grafic_b_p <- renderPlot({
    p <- 50:500
    b <- taxa_benefici(p = p, c = input$c, v = input$v)
    plot(p, b, xlab = "Plusvàlua (pv)", ylab = "Taxa de benefici (b')", type = "l")
  })
  
  output$k3_s1_grafic_b_cvp <- renderPlotly({
    x <- 50:200
    b <- data.frame(
      x = x,
      c = taxa_benefici(p = input$p, c = x, v = input$v),
      v = taxa_benefici(p = input$p, c = input$c, v = x),
      p = taxa_benefici(p = x, c = input$c, v = input$v)
    )
    
    b_long <- tidyr::pivot_longer(b, cols = c(c, v, p), names_to = "variable", values_to = "valor")
    
    gg <- ggplot(b_long, aes(x = x, y = valor, color = variable)) +
      geom_line(key_glyph = draw_key_abline) +
      scale_color_manual(values = c("c" = "green", "v" = "red", "p" = "black")) +
      ylab("Taxa de benefici (b')") + xlab("Component del capital") 
    plotly::ggplotly(gg)
  })
  
  output$k3_s1_grafic_p_cvp <- renderPlotly({
    x <- 50:200
    p <- data.frame(
      x = x,
      c = taxa_plusvalua(p = input$p, v = input$v),
      v = taxa_plusvalua(p = input$p, v = x),
      p = taxa_plusvalua(p = x, v = input$v)
    )
    
    p_long <- tidyr::pivot_longer(p, cols = c(c, v, p), names_to = "variable", values_to = "valor")
    
    gg <- ggplot(p_long, aes(x = x, y = valor, color = variable)) +
      geom_line(key_glyph = draw_key_abline) +
      scale_color_manual(values = c("c" = "green", "v" = "red", "p" = "black")) +
      ylab("Taxa de d'explotació (pv')") + xlab("Component del capital") 
    plotly::ggplotly(gg)
  })
  
  
  ### Capítol 3 ----

  output$K3s1_b <- renderPlot({
    x <- faithful[, 2] # Old Faithful Geyser data
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    hist(x,
         breaks = bins, col = "darkgray", border = "white",
         xlab = "Waiting time to next eruption (in mins)",
         main = "Histogram of waiting times"
    )
  })

  
  ### Capítol 6 ----
  
  # Càlcul de la taxa de guany
  calcular_taxa_guany <- reactive({
    c <- input$capital_constant * input$factor_c
    v <- input$capital_variable * input$factor_v
    pv <- input$plusvalua * input$factor_pv
    
    taxa_original <- input$plusvalua / (input$capital_constant + input$capital_variable)
    taxa_nova <- pv / (c + v)
    
    list(
      original = taxa_original,
      nova = taxa_nova,
      canvi = taxa_nova - taxa_original,
      percentatge_canvi = (taxa_nova - taxa_original) / taxa_original * 100
    )
  })
  
  # Resultats numèrics
  output$resultat_formula <- renderPrint({
    resultats <- calcular_taxa_guany()
    cat("Taxa de guany original: ", round(resultats$original * 100, 2), "%\n")
    cat("Taxa de guany nova: ", round(resultats$nova * 100, 2), "%\n")
    cat("Canvi absolut: ", round(resultats$canvi * 100, 2), " punts percentuals\n")
    cat("Canvi relatiu: ", round(resultats$percentatge_canvi, 2), "%\n")
  })
  
  # Gràfic de la taxa de guany
  output$grafic_taxa_guany <- renderPlot({
    resultats <- calcular_taxa_guany()
    
    df <- data.frame(
      Categoria = c("Original", "Nova"),
      Taxa = c(resultats$original, resultats$nova)
    )
    
    ggplot(df, aes(x = Categoria, y = Taxa, fill = Categoria)) +
      geom_col(alpha = 0.8) +
      geom_text(aes(label = paste0(round(Taxa * 100, 2), "%")), 
                vjust = -0.5, size = 5) +
      scale_fill_manual(values = c("Original" = "#2E86AB", "Nova" = "#A23B72")) +
      labs(title = "Comparació de la Taxa de Guany",
           y = "Taxa de Guany", x = "") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none")
  })
  
  # Gràfic dels components del capital
  output$grafic_components <- renderPlot({
    c_original <- input$capital_constant
    v_original <- input$capital_variable
    pv_original <- input$plusvalua
    
    c_nou <- input$capital_constant * input$factor_c
    v_nou <- input$capital_variable * input$factor_v
    pv_nou <- input$plusvalua * input$factor_pv
    
    df <- data.frame(
      Component = rep(c("c", "v", "pv"), 2),
      Valor = c(c_original, v_original, pv_original, c_nou, v_nou, pv_nou),
      Periode = rep(c("Original", "Nou"), each = 3)
    )
    
    ggplot(df, aes(x = Component, y = Valor, fill = Periode)) +
      geom_col(position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("Original" = "#2E86AB", "Nou" = "#A23B72")) +
      labs(title = "Comparació dels Components del Capital",
           y = "Valor", x = "Component") +
      theme_minimal(base_size = 14)
  })
  
  # Anàlisi amb ryacas - Derivades
  output$derivades <- renderPrint({
    # Definim les variables simbòliques
    c <- ysym("c")
    v <- ysym("v")
    pv <- ysym("pv")
    
    # Fórmula de la taxa de guany
    taxa_guany <- pv / (c + v)
    
    cat("FÓRMULA DE LA TAXA DE GUANY:\n")
    print(taxa_guany)
    cat("\n")
    
    cat("DERIVADES PARCIALS:\n")
    cat("Respecte a c (capital constant):\n")
    print(deriv(taxa_guany, c))
    cat("\nRespecte a v (capital variable):\n")
    print(deriv(taxa_guany, v))
    cat("\nRespecte a pv (plusvàlua):\n")
    print(deriv(taxa_guany, pv))
  })
  
  # Gràfic de sensibilitat
  output$grafic_sensibilitat <- renderPlot({
    # Creem un rang de valors per als factors
    factors <- seq(0.5, 2, by = 0.1)
    
    sensibilitat_df <- data.frame()
    
    for (factor in factors) {
      # Variem cada factor individualment
      c_nou <- input$capital_constant * factor
      v_nou <- input$capital_variable
      pv_nou <- input$plusvalua
      taxa_c <- pv_nou / (c_nou + v_nou)
      
      c_nou <- input$capital_constant
      v_nou <- input$capital_variable * factor
      pv_nou <- input$plusvalua
      taxa_v <- pv_nou / (c_nou + v_nou)
      
      c_nou <- input$capital_constant
      v_nou <- input$capital_variable
      pv_nou <- input$plusvalua * factor
      taxa_pv <- pv_nou / (c_nou + v_nou)
      
      sensibilitat_df <- rbind(sensibilitat_df,
                               data.frame(
                                 Factor = factor,
                                 `Canvi en c` = taxa_c,
                                 `Canvi en v` = taxa_v,
                                 `Canvi en pv` = taxa_pv
                               ))
    }
    
    sensibilitat_long <- tidyr::pivot_longer(sensibilitat_df, 
                                             cols = c("Canvi.en.c", "Canvi.en.v", "Canvi.en.pv"),
                                             names_to = "Component", 
                                             values_to = "Taxa_Guany")
    
    ggplot(sensibilitat_long, aes(x = Factor, y = Taxa_Guany, color = Component)) +
      geom_line(linewidth = 1.5) +
      geom_vline(xintercept = 1, linetype = "dashed", alpha = 0.5) +
      scale_color_manual(values = c("Canvi.en.c" = "#E56B70", 
                                    "Canvi.en.v" = "#4CB5AE", 
                                    "Canvi.en.pv" = "#F0C987")) +
      labs(title = "Sensibilitat de la Taxa de Guany als Canvis de Preus",
           x = "Factor de Canvi", y = "Taxa de Guany") +
      theme_minimal(base_size = 14)
  })
  
  # Explicació teòrica
  output$explicacio_teorica <- renderUI({
    withMathJax(HTML("
    <div style='font-size: 16px; line-height: 1.6;'>
      <h4>Conceptes Clau del Capítol VI:</h4>
      <p><strong>Taxa de Guany (p'):</strong> Relació entre la plusvàlua i el capital total avançat: $$p' = \\frac{pv}{c + v}$$</p>
      
      <p><strong>Efectes dels Canvis de Preus:</strong></p>
      <ul>
        <li><strong>Capital Constant (c):</strong> Quan els mitjans de producció augmenten de preu, la taxa de guany disminueix</li>
        <li><strong>Capital Variable (v):</strong> Canvis en el salari afecten tant 'v' com la plusvàlua</li>
        <li><strong>Plusvàlua (pv):</strong> Canvis en la productivitat o explotació modifiquen directament la taxa de guany</li>
      </ul>
      
      <p><strong>Relació amb la Composició Orgànica:</strong> $$OCC = \\frac{c}{v}$$</p>
      <p>Taxa de Guany en funció de OCC: $$p' = \\frac{pv}{v} \\times \\frac{1}{OCC + 1}$$</p>
    </div>
    "))
  })
  
  # Fórmules de teoria
  output$formules_teoria <- renderUI({
    withMathJax(HTML("
        <h4>Fórmules Fonamentals:</h4>
        <p>1. <strong>Taxa de Guany:</strong> $$p' = \\frac{pv}{c + v}$$</p>
        <p>2. <strong>Taxa de Plusvàlua:</strong> $$pv' = \\frac{pv}{v}$$</p>
        <p>3. <strong>Composició Orgànica del Capital:</strong> $$OCC = \\frac{c}{v}$$</p>
        <p>4. <strong>Relació entre Taxa de Guany i OCC:</strong> $$p' = \\frac{pv'}{OCC + 1}$$</p>
        <p>5. <strong>Derivada respecte a c:</strong> $$\\frac{\\partial p'}{\\partial c} = -\\frac{pv}{(c + v)^2}$$</p>
        <p>6. <strong>Derivada respecte a v:</strong> $$\\frac{\\partial p'}{\\partial v} = \\frac{c \\cdot pv}{(c + v)^2} - \\frac{pv}{(c + v)^2}$$</p>
      "))
  })
}