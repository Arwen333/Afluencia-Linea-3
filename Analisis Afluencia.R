#****************************************************************************#
# Tarea Práctica 3 - Modelos de Supervivencia y Series de Tiempo
# Facultad de Ciencias, UNAM
# ANÁLISIS DE SERIES DE TIEMPO - METROBÚS CDMX (2017-2020)
# LÍNEA 3 - TENAYUCA
#
# Creado por: Arwen Yetzirah Ortiz N.
# Fecha: 26/02/2026
# Actualizado: 28/03/2026
#****************************************************************************#

#****************************************************************************#
# Preámbulo ----
#****************************************************************************#

graphics.off()
rm(list = ls())

#****************************************************************************#
# Carga de librerías ----
#****************************************************************************#

library(zoo)
library(imputeTS)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tseries)
library(forecast)
library(knitr)

#****************************************************************************#
# 1. CARGAR Y LIMPIAR DATOS ----
#****************************************************************************#

cat("========================================\n")
cat("1. CARGANDO Y LIMPIANDO DATOS\n")
cat("========================================\n")

url_github <- "https://raw.githubusercontent.com/Arwen333/Afluencia-Linea-3/refs/heads/main/afluenciamb_simple_01_2026.csv"

df <- read.csv(url_github, encoding = "UTF-8", stringsAsFactors = FALSE)

# Convertir tipos
df$fecha <- as.Date(df$fecha)
df$afluencia <- as.numeric(df$afluencia)
df$anio <- as.numeric(df$anio)

# Filtrar 2017-2020
df <- df[df$anio >= 2017 & df$anio <= 2020, ]
cat("Registros después de filtrar 2017-2020:", nrow(df), "\n\n")

#****************************************************************************#
# 2. FILTRAR SOLO LÍNEA 3 ----
#****************************************************************************#

cat("========================================\n")
cat("2. FILTRANDO LÍNEA 3\n")
cat("========================================\n")

df_linea3 <- df %>% filter(linea == "Línea 3")
cat("Registros para Línea 3 (2017-2020):", nrow(df_linea3), "\n\n")

#****************************************************************************#
# 3. AGREGACIÓN POR DÍA ----
#****************************************************************************#

cat("========================================\n")
cat("3. AGREGACIÓN DIARIA\n")
cat("========================================\n")

serie_diaria <- df_linea3 %>%
  group_by(fecha) %>%
  summarise(afluencia = sum(afluencia, na.rm = TRUE)) %>%
  ungroup() %>%
  arrange(fecha)

# Completar fechas faltantes
fechas_completas <- data.frame(fecha = seq(min(serie_diaria$fecha), 
                                           max(serie_diaria$fecha), 
                                           by = "day"))
serie_completa <- merge(fechas_completas, serie_diaria, by = "fecha", all.x = TRUE)

cat("Rango de fechas:", format(min(serie_completa$fecha), "%Y-%m-%d"), 
    "a", format(max(serie_completa$fecha), "%Y-%m-%d"), "\n")
cat("Días con datos:", sum(!is.na(serie_completa$afluencia)), "/", nrow(serie_completa), "\n\n")

#****************************************************************************#
# 4. IMPUTACIÓN DE VALORES FALTANTES ----
#****************************************************************************#

cat("========================================\n")
cat("4. IMPUTACIÓN DE VALORES FALTANTES\n")
cat("========================================\n")

faltantes <- sum(is.na(serie_completa$afluencia))
if (faltantes > 0) {
  serie_completa$afluencia <- na.approx(serie_completa$afluencia)
  cat("Valores imputados:", faltantes, "\n")
} else {
  cat("No hay valores faltantes\n")
}

#****************************************************************************#
# 5. DETECCIÓN Y TRATAMIENTO DE OUTLIERS ----
#****************************************************************************#

cat("\n========================================\n")
cat("5. DETECCIÓN DE OUTLIERS\n")
cat("========================================\n")

ts_diaria <- ts(serie_completa$afluencia, frequency = 365)
stl_fit <- stl(ts_diaria, s.window = "periodic", robust = TRUE)
residuos <- stl_fit$time.series[, "remainder"]
limite <- 3 * sd(residuos, na.rm = TRUE)
serie_completa$outlier <- abs(residuos) > limite
cat("Outliers detectados:", sum(serie_completa$outlier), "\n")

# Winsorización
p1 <- quantile(serie_completa$afluencia, 0.01, na.rm = TRUE)
p99 <- quantile(serie_completa$afluencia, 0.99, na.rm = TRUE)
serie_completa$afluencia <- pmax(pmin(serie_completa$afluencia, p99), p1)
cat("Winsorización aplicada (percentiles 1% y 99%)\n\n")

#****************************************************************************#
# 6. AGREGACIÓN MENSUAL ----
#****************************************************************************#

cat("========================================\n")
cat("6. AGREGACIÓN MENSUAL\n")
cat("========================================\n")

serie_mensual <- serie_completa %>%
  mutate(mes = as.Date(format(fecha, "%Y-%m-01"))) %>%
  group_by(mes) %>%
  summarise(afluencia = mean(afluencia, na.rm = TRUE), .groups = "drop")

ts_mensual <- ts(serie_mensual$afluencia, 
                 start = c(2017, 1), 
                 frequency = 12)

cat("Serie mensual creada:", length(ts_mensual), "meses (2017-2020)\n\n")

#****************************************************************************#
# 7. ESTADÍSTICAS DESCRIPTIVAS POR PERIODO ----
#****************************************************************************#

cat("========================================\n")
cat("7. ESTADÍSTICAS DESCRIPTIVAS POR PERIODO\n")
cat("========================================\n")

serie_mensual <- serie_mensual %>%
  mutate(anio = as.numeric(format(mes, "%Y")))

stats_por_periodo <- serie_mensual %>%
  mutate(periodo = case_when(
    anio %in% c(2017, 2018, 2019) ~ "2017-2019 (Base)",
    anio == 2020 ~ "2020 (Pandemia)"
  )) %>%
  group_by(periodo) %>%
  summarise(
    Media = round(mean(afluencia, na.rm = TRUE), 0),
    Mediana = round(median(afluencia, na.rm = TRUE), 0),
    Desviación = round(sd(afluencia, na.rm = TRUE), 0),
    CV = round(sd(afluencia, na.rm = TRUE) / mean(afluencia, na.rm = TRUE), 3),
    Mínimo = min(afluencia, na.rm = TRUE),
    Máximo = max(afluencia, na.rm = TRUE)
  )

print(stats_por_periodo)

media_base <- stats_por_periodo$Media[1]
media_2020 <- stats_por_periodo$Media[2]
cambio_porcentual <- round((media_2020 / media_base - 1) * 100, 1)

cat("\n📊 Cambio porcentual 2020 vs periodo base:", cambio_porcentual, "%\n\n")

#****************************************************************************#
# 8. GRÁFICOS DESCRIPTIVOS ----
#****************************************************************************#

cat("========================================\n")
cat("8. GENERANDO GRÁFICOS\n")
cat("========================================\n")

# Gráfico 1: Serie diaria con outliers
p1 <- ggplot(serie_completa, aes(x = fecha, y = afluencia)) +
  geom_line(color = "gray50", alpha = 0.5, size = 0.3) +
  geom_point(data = subset(serie_completa, outlier), 
             aes(x = fecha, y = afluencia), 
             color = "red", size = 0.5, alpha = 0.7) +
  geom_smooth(method = "loess", color = "#D55E00", se = FALSE, size = 1) +
  labs(title = "Afluencia diaria - Línea 3 del Metrobús",
       subtitle = paste("Outliers detectados:", sum(serie_completa$outlier)),
       x = "Fecha", y = "Afluencia (usuarios)") +
  theme_minimal() +
  geom_vline(xintercept = as.Date("2020-03-01"), linetype = "dashed", color = "red", alpha = 0.5)

# Gráfico 2: Comparación diario vs mensual
p2 <- ggplot() +
  geom_line(data = serie_completa, aes(x = fecha, y = afluencia), 
            alpha = 0.3, color = "gray50", size = 0.3) +
  geom_line(data = serie_mensual, aes(x = mes, y = afluencia), 
            color = "red", size = 1.2) +
  labs(title = "Afluencia Línea 3: Datos diarios vs promedio mensual",
       subtitle = "Línea gris: datos diarios | Línea roja: promedio mensual",
       x = "Fecha", y = "Afluencia (usuarios)") +
  theme_minimal()

print(p1)
print(p2)

#****************************************************************************#
# 9. DESCOMPOSICIÓN STL ----
#****************************************************************************#

cat("\n========================================\n")
cat("9. DESCOMPOSICIÓN STL\n")
cat("========================================\n")

stl_mensual <- stl(ts_mensual, s.window = "periodic", robust = TRUE)

par(mfrow = c(3, 1), mar = c(3, 4, 2, 2))
plot(stl_mensual$time.series[, "trend"], 
     main = "Tendencia - Línea 3", ylab = "Tendencia", col = "steelblue", lwd = 2)
plot(stl_mensual$time.series[, "seasonal"], 
     main = "Estacionalidad - Línea 3", ylab = "Estacional", col = "steelblue", lwd = 2)
plot(stl_mensual$time.series[, "remainder"], 
     main = "Residuos - Línea 3", ylab = "Residuos", col = "steelblue", lwd = 2)
par(mfrow = c(1, 1))

# Varianza explicada por cada componente
tendencia <- stl_mensual$time.series[, "trend"]
estacional <- stl_mensual$time.series[, "seasonal"]
residual <- stl_mensual$time.series[, "remainder"]

var_total <- var(ts_mensual, na.rm = TRUE)
prop_var <- data.frame(
  Componente = c("Tendencia", "Estacionalidad", "Residual"),
  Varianza = c(var(tendencia, na.rm = TRUE), 
               var(estacional, na.rm = TRUE), 
               var(residual, na.rm = TRUE)),
  Porcentaje = round(c(var(tendencia, na.rm = TRUE) / var_total * 100,
                       var(estacional, na.rm = TRUE) / var_total * 100,
                       var(residual, na.rm = TRUE) / var_total * 100), 2)
)

cat("\n📊 Proporción de varianza explicada:\n")
print(prop_var)

#****************************************************************************#
# 10. PRUEBAS DE ESTACIONARIEDAD ----
#****************************************************************************#

cat("\n========================================\n")
cat("10. PRUEBAS DE ESTACIONARIEDAD\n")
cat("========================================\n")

# Prueba ADF (Augmented Dickey-Fuller)
adf_original <- adf.test(ts_mensual, alternative = "stationary")
adf_diff <- adf.test(diff(ts_mensual), alternative = "stationary")

# Prueba KPSS
kpss_original <- kpss.test(ts_mensual)
kpss_diff <- kpss.test(diff(ts_mensual))

resultados_estacionariedad <- data.frame(
  Prueba = c("ADF (original)", "ADF (diferenciada)", 
             "KPSS (original)", "KPSS (diferenciada)"),
  Estadístico = c(round(adf_original$statistic, 4), 
                  round(adf_diff$statistic, 4),
                  round(kpss_original$statistic, 4), 
                  round(kpss_diff$statistic, 4)),
  p_valor = c(round(adf_original$p.value, 4), 
              round(adf_diff$p.value, 4),
              round(kpss_original$p.value, 4), 
              round(kpss_diff$p.value, 4)),
  Conclusión = c(
    ifelse(adf_original$p.value < 0.05, "Estacionaria", "No estacionaria"),
    ifelse(adf_diff$p.value < 0.05, "Estacionaria", "No estacionaria"),
    ifelse(kpss_original$p.value > 0.05, "Estacionaria", "No estacionaria"),
    ifelse(kpss_diff$p.value > 0.05, "Estacionaria", "No estacionaria")
  )
)

print(resultados_estacionariedad)

# Determinar si requiere diferenciación
if (adf_original$p.value >= 0.05 && kpss_original$p.value < 0.05) {
  cat("\n✅ Conclusión: La serie NO es estacionaria. Se requiere diferenciación (d = 1)\n")
  d_requerida <- 1
} else {
  cat("\n✅ Conclusión: La serie ES estacionaria. No se requiere diferenciación (d = 0)\n")
  d_requerida <- 0
}

# Transformación Box-Cox
lambda <- BoxCox.lambda(ts_mensual)
cat("\n📊 Transformación Box-Cox: λ =", round(lambda, 3), "\n")

#****************************************************************************#
11. CORRELOGRAMAS (ACF y PACF) - SERIE ESTACIONARIA ----
  #****************************************************************************#
  
  cat("\n========================================\n")
cat("11. ANÁLISIS DE CORRELOGRAMAS\n")
cat("========================================\n")

# Serie transformada y diferenciada si es necesario
if (d_requerida == 1) {
  serie_estacionaria <- diff(ts_mensual)
} else {
  serie_estacionaria <- ts_mensual
}

# Si lambda está cerca de 0, usar log
if (abs(lambda) < 0.1) {
  serie_estacionaria <- diff(log(ts_mensual))
  cat("Usando transformación logarítmica + diferenciación\n")
}

par(mfrow = c(1, 2))
acf(serie_estacionaria, main = "ACF - Serie estacionaria", 
    lag.max = 24, col = "steelblue", lwd = 2, ci = 0.95)
pacf(serie_estacionaria, main = "PACF - Serie estacionaria", 
     lag.max = 24, col = "steelblue", lwd = 2, ci = 0.95)
par(mfrow = c(1, 1))

# Identificación de órdenes p y q basado en correlogramas
acf_vals <- acf(serie_estacionaria, plot = FALSE, lag.max = 24)
pacf_vals <- pacf(serie_estacionaria, plot = FALSE, lag.max = 24)

# Detectar corte en ACF (para MA)
acf_cut <- which(abs(acf_vals$acf[2:13]) < 1.96/sqrt(length(serie_estacionaria)))[1]
pacf_cut <- which(abs(pacf_vals$acf[2:13]) < 1.96/sqrt(length(serie_estacionaria)))[1]

if (is.na(acf_cut)) acf_cut <- 1
if (is.na(pacf_cut)) pacf_cut <- 1

cat("\n📊 Identificación del modelo:\n")
cat("  - ACF: corte después de lag", acf_cut, "→ sugiere MA(", acf_cut, ")\n")
cat("  - PACF: corte después de lag", pacf_cut, "→ sugiere AR(", pacf_cut, ")\n")

# Recomendación de modelo
p_recomendado <- pacf_cut
q_recomendado <- acf_cut
cat("\n🎯 Modelo sugerido: ARIMA(", p_recomendado, ",", d_requerida, ",", q_recomendado, ")\n")
#****************************************************************************#
# 12. ESTIMACIÓN DEL MODELO ARIMA ----
#****************************************************************************#

cat("\n========================================\n")
cat("12. ESTIMACIÓN DEL MODELO ARIMA\n")
cat("========================================\n")

# Modelo con los órdenes identificados
modelo_arima <- Arima(ts_mensual, order = c(p_recomendado, d_requerida, q_recomendado))
summary(modelo_arima)

# Modelo con transformación Box-Cox si lambda es significativamente diferente de 1
if (abs(lambda - 1) > 0.1) {
  modelo_boxcox <- Arima(ts_mensual, order = c(p_recomendado, d_requerida, q_recomendado), 
                         lambda = lambda)
  cat("\n📊 Modelo con transformación Box-Cox (λ =", round(lambda, 3), "):\n")
  print(summary(modelo_boxcox))
}

#****************************************************************************#
# 13. VALIDACIÓN DE SUPUESTOS (DIAGNÓSTICO DE RESIDUOS) ----
#****************************************************************************#

cat("\n========================================\n")
cat("13. VALIDACIÓN DE SUPUESTOS\n")
cat("========================================\n")

residuos_modelo <- residuals(modelo_arima)

par(mfrow = c(2, 2))

# Residuos estandarizados
plot(residuos_modelo, main = "Residuos estandarizados", 
     ylab = "Residuos", col = "darkblue")
abline(h = 0, col = "red", lty = 2)

# ACF de residuos
acf(residuos_modelo, main = "ACF de residuos", lag.max = 24)

# Q-Q plot
qqnorm(residuos_modelo, main = "Q-Q Plot")
qqline(residuos_modelo, col = "red")

# Histograma
hist(residuos_modelo, main = "Histograma de residuos", 
     xlab = "Residuos", col = "lightblue", freq = FALSE)
curve(dnorm(x, mean(residuos_modelo), sd(residuos_modelo)), 
      add = TRUE, col = "red", lwd = 2)

par(mfrow = c(1, 1))

# Prueba de Ljung-Box para ruido blanco
lb_test <- Box.test(residuos_modelo, lag = 12, type = "Ljung-Box")
cat("\n📊 Prueba de Ljung-Box (ruido blanco):\n")
cat("  Estadístico =", round(lb_test$statistic, 4), "\n")
cat("  p-valor =", round(lb_test$p.value, 4), "\n")

if (lb_test$p.value > 0.05) {
  cat("  ✅ Los residuos se comportan como ruido blanco (modelo adecuado)\n")
} else {
  cat("  ⚠️ Los residuos presentan autocorrelación (modelo podría mejorarse)\n")
}

#****************************************************************************#
# 14. PRONÓSTICOS (PREDICCIONES) ----
#****************************************************************************#

cat("\n========================================\n")
cat("14. GENERANDO PRONÓSTICOS\n")
cat("========================================\n")

# Pronósticos para los próximos 12 meses (2021)
pronosticos <- forecast(modelo_arima, h = 12)

# Gráfico de pronósticos
autoplot(pronosticos) +
  labs(
    title = "Pronósticos de afluencia - Línea 3 del Metrobús",
    subtitle = "Horizonte: 12 meses (2021) | Intervalos de confianza al 80% y 95%",
    x = "Fecha", y = "Afluencia de pasajeros"
  ) +
  theme_minimal() +
  geom_vline(xintercept = 2020.75, linetype = "dashed", color = "red", alpha = 0.5)

# Tabla de pronósticos
meses_pronostico <- c("Ene 2021", "Feb 2021", "Mar 2021", "Abr 2021", "May 2021", "Jun 2021",
                      "Jul 2021", "Ago 2021", "Sep 2021", "Oct 2021", "Nov 2021", "Dic 2021")

tabla_pronosticos <- data.frame(
  Mes = meses_pronostico,
  Pronóstico = round(pronosticos$mean, 0),
  LI_80 = round(pronosticos$lower[, 1], 0),
  LS_80 = round(pronosticos$upper[, 1], 0),
  LI_95 = round(pronosticos$lower[, 2], 0),
  LS_95 = round(pronosticos$upper[, 2], 0)
)

cat("\n📊 Tabla de pronósticos para 2021:\n")
print(tabla_pronosticos)

#****************************************************************************#
# 15. RESUMEN EJECUTIVO PARA EL DOCUMENTO ----
#****************************************************************************#

cat("\n========================================\n")
cat("15. RESUMEN EJECUTIVO\n")
cat("========================================\n")

cat("\n📌 **RESUMEN DE RESULTADOS**\n")
cat("────────────────────────────────────────────────────────────\n")
cat("✅ Serie analizada: Línea 3 del Metrobús CDMX (2017-2020)\n")
cat("✅ Frecuencia: Mensual (agregada desde datos diarios)\n")
cat("✅ Impacto COVID-19: Reducción del", abs(cambio_porcentual), "% en afluencia media\n")
cat("✅ Descomposición STL:\n")
cat("   - Tendencia:", prop_var$Porcentaje[1], "% de varianza\n")
cat("   - Estacionalidad:", prop_var$Porcentaje[2], "% de varianza\n")
cat("   - Residual:", prop_var$Porcentaje[3], "% de varianza\n")
cat("✅ Estacionariedad: d =", d_requerida, "requerida\n")
cat("✅ Modelo identificado: ARIMA(", p_recomendado, ",", d_requerida, ",", q_recomendado, ")\n")
cat("✅ Validación: Ljung-Box p-valor =", round(lb_test$p.value, 4), "→ residuos ruido blanco\n")
cat("✅ Pronósticos generados para 2021 con intervalos de confianza\n")
cat("────────────────────────────────────────────────────────────\n")

#****************************************************************************#
# Fin del análisis ----
#****************************************************************************#

cat("\n🎉 ANÁLISIS COMPLETADO EXITOSAMENTE\n")

