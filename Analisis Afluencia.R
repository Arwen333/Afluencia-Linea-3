#****************************************************************************#
#************************************************************************************************#
#
#           Tarea Practica 1 Modelos de Supervivencia y Series de Tiempo
#                         Facultad de Ciencias UNAM
#            ANÁLISIS DE SERIES DE TIEMPO - METROBÚS CDMX (2017-2020)  
#                         LÍNEA 3 - TENAYUCA
#
#         Creado por:               Arwen Yetzirah Ortiz N.
#         Fecha de creación:        26/02/2026
#         Actualizado por:          Arwen Yetzirah Ortiz N. 
#         Fecha de actualización:   1/03/2026
#         Contacto:                 arwenort@ciencias.unam.mx
#                         
#************************************************************************************************#
#************************************************************************************************#

#************************************************************************************************#
# Preámbulo ----
#************************************************************************************************#

## Limpieza de gráficas----
graphics.off()

## Limpieza de memoria
rm(list=ls())

#************************************************************************************************#
# Carga de librerías ----
#************************************************************************************************#

library(zoo)
library(imputeTS)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tseries)
library(forecast)

#************************************************************************************************#
# 1. CARGAR Y LIMPIAR DATOS ----
#************************************************************************************************#

cat("========================================\n")
cat("1. CARGANDO Y LIMPIANDO DATOS\n")
cat("========================================\n")

# NUEVA URL: Cargar datos directamente desde GitHub
url_github <- "https://raw.githubusercontent.com/Arwen333/Afluencia-Linea-3/refs/heads/main/afluenciamb_simple_01_2026.csv"

df <- read.csv(url_github, 
               encoding = "UTF-8", 
               stringsAsFactors = FALSE)

# Exploración inicial
cat("Estructura del dataset:\n")
str(df)
cat("\nPrimeras filas:\n")
print(head(df))
cat("\n")

# Convertir tipos de datos
df$fecha <- as.Date(df$fecha)
df$afluencia <- as.numeric(df$afluencia)
df$anio <- as.numeric(df$anio)

# Filtrar 2017-2020 
cat("Rango completo de fechas en datos:", 
    format(min(df$fecha), "%Y-%m-%d"), "a", 
    format(max(df$fecha), "%Y-%m-%d"), "\n")

df <- df[df$anio >= 2017 & df$anio <= 2020, ]

cat("Registros después de filtrar 2017-2020:", nrow(df), "\n\n")

#************************************************************************************************#
# 2. FILTRAR SOLO LÍNEA 3 ----
#************************************************************************************************#

cat("========================================\n")
cat("2. FILTRANDO LÍNEA 3\n")
cat("========================================\n")

# Verificar valores únicos en la columna 'linea'
cat("Líneas disponibles en los datos:\n")
print(unique(df$linea))
cat("\n")

# Filtrar para Línea 3
df_linea3 <- df %>%
  filter(linea == "Línea 3")

cat("Registros para Línea 3 (2017-2020):", nrow(df_linea3), "\n")

if (nrow(df_linea3) == 0) {
  cat("⚠️ ADVERTENCIA: No hay registros para Línea 3 en 2017-2020.\n")
  cat("Verificando si existe Línea 3 en otros años...\n")
  
  # Verificar si hay datos de Línea 3 en todo el dataset
  df_temp <- read.csv(url_github, encoding = "UTF-8", stringsAsFactors = FALSE)
  df_temp$fecha <- as.Date(df_temp$fecha)
  df_temp$anio <- as.numeric(format(df_temp$fecha, "%Y"))
  
  cat("Años con datos de Línea 3:\n")
  print(unique(df_temp$anio[df_temp$linea == "Línea 3"]))
  
  stop("No hay datos de Línea 3 para el período 2017-2020. Deteniendo análisis.")
}

#************************************************************************************************#
# 3. AGREGACIÓN POR DÍA (LÍNEA 3) ----
#************************************************************************************************#

cat("\n========================================\n")
cat("3. AGREGACIÓN DIARIA - LÍNEA 3\n")
cat("========================================\n")

# Agregar por día (NOTA: En esta estructura, cada día tiene un registro por línea)
# Por lo tanto, para Línea 3 ya tenemos un valor diario directamente
serie_diaria <- df_linea3 %>%
  select(fecha, afluencia) %>%
  arrange(fecha)

# Verificar si hay múltiples registros para el mismo día 
duplicados <- serie_diaria %>%
  group_by(fecha) %>%
  summarise(n = n()) %>%
  filter(n > 1)

if (nrow(duplicados) > 0) {
  cat("⚠️ Advertencia: Hay", nrow(duplicados), "fechas duplicadas. Sumando valores...\n")
  serie_diaria <- df_linea3 %>%
    group_by(fecha) %>%
    summarise(afluencia = sum(afluencia, na.rm = TRUE)) %>%
    ungroup() %>%
    arrange(fecha)
}

# Completar fechas faltantes
fechas_completas <- data.frame(fecha = seq(min(serie_diaria$fecha), 
                                           max(serie_diaria$fecha), 
                                           by = "day"))
serie_completa <- merge(fechas_completas, serie_diaria, by = "fecha", all.x = TRUE)

cat("Rango de fechas (Línea 3):", format(min(serie_completa$fecha), "%Y-%m-%d"), 
    "a", format(max(serie_completa$fecha), "%Y-%m-%d"), "\n")
cat("Total de días en el período:", nrow(serie_completa), "\n")
cat("Días con datos en Línea 3:", sum(!is.na(serie_completa$afluencia)), "\n\n")

#************************************************************************************************#
# 4. IMPUTACIÓN DE VALORES FALTANTES ----
#************************************************************************************************#

cat("========================================\n")
cat("4. IMPUTACIÓN DE VALORES FALTANTES\n")
cat("========================================\n")

faltantes <- sum(is.na(serie_completa$afluencia))
porcentaje_faltantes <- round(100 * faltantes / nrow(serie_completa), 2)
cat("Valores faltantes:", faltantes, paste0("(", porcentaje_faltantes, "%)\n"))

if (faltantes > 0) {
  # Imputación lineal
  serie_completa$afluencia <- na.approx(serie_completa$afluencia)
  cat("Valores imputados correctamente\n")
} else {
  cat("No hay valores faltantes\n")
}
cat("\n")

#************************************************************************************************#
# 5. DETECCIÓN Y TRATAMIENTO DE OUTLIERS ----
#************************************************************************************************#

cat("========================================\n")
cat("5. DETECCIÓN DE OUTLIERS\n")
cat("========================================\n")

# Método STL para detección de outliers
ts_diaria <- ts(serie_completa$afluencia, frequency = 365)
stl_fit <- stl(ts_diaria, s.window = "periodic", robust = TRUE) # robust = TRUE para mejor manejo
residuos <- stl_fit$time.series[, "remainder"]
limite <- 3 * sd(residuos, na.rm = TRUE)

serie_completa$outlier <- abs(residuos) > limite
cat("Outliers detectados (STL):", sum(serie_completa$outlier), "\n")

# Winsorización (limitar valores extremos)
p1 <- quantile(serie_completa$afluencia, 0.01, na.rm = TRUE)
p99 <- quantile(serie_completa$afluencia, 0.99, na.rm = TRUE)
serie_completa$afluencia <- pmax(pmin(serie_completa$afluencia, p99), p1)
cat("Winsorización aplicada (percentiles 1% y 99%)\n\n")

#************************************************************************************************#
# 6. AGREGACIÓN MENSUAL ----
#************************************************************************************************#

cat("========================================\n")
cat("6. AGREGACIÓN MENSUAL - LÍNEA 3\n")
cat("========================================\n")

serie_mensual <- serie_completa %>%
  mutate(mes = as.Date(format(fecha, "%Y-%m-01"))) %>%
  group_by(mes) %>%
  summarise(afluencia = mean(afluencia, na.rm = TRUE), .groups = "drop")

ts_mensual <- ts(serie_mensual$afluencia, 
                 start = c(as.numeric(format(min(serie_mensual$mes), "%Y")), 
                           as.numeric(format(min(serie_mensual$mes), "%m"))), 
                 frequency = 12)

cat("Serie mensual creada (Línea 3):", length(ts_mensual), "meses\n")
cat("Rango:", start(ts_mensual)[1], "-", end(ts_mensual)[1], "\n\n")

#************************************************************************************************#
# 7. GRÁFICOS ----
#************************************************************************************************#

cat("========================================\n")
cat("7. GENERANDO GRÁFICOS - LÍNEA 3\n")
cat("========================================\n")

# Gráfico 1: Serie diaria completa con outliers
p1 <- ggplot(serie_completa, aes(x = fecha, y = afluencia)) +
  geom_line(color = "steelblue", size = 0.5) +
  geom_point(data = subset(serie_completa, outlier), 
             aes(x = fecha, y = afluencia), 
             color = "red", size = 1, alpha = 0.7) +
  labs(title = "Afluencia diaria del Metrobús - Línea 3 (2017-2020)",
       subtitle = paste("Outliers detectados:", sum(serie_completa$outlier)),
       x = "Fecha", 
       y = "Afluencia (usuarios)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

# Gráfico 2: Comparación diario vs mensual
p2 <- ggplot() +
  geom_line(data = serie_completa, aes(x = fecha, y = afluencia), 
            alpha = 0.3, color = "gray50", size = 0.3) +
  geom_line(data = serie_mensual, aes(x = mes, y = afluencia), 
            color = "red", size = 1) +
  labs(title = "Afluencia Línea 3: Diario vs Mensual",
       subtitle = "Línea gris: datos diarios | Línea roja: promedio mensual",
       x = "Fecha", 
       y = "Afluencia (usuarios)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

# Mostrar gráficos
print(p1)
print(p2)

# Gráfico 3: Descomposición STL de la serie mensual
stl_mensual <- stl(ts_mensual, s.window = "periodic", robust = TRUE)

par(mfrow = c(3, 1), mar = c(3, 4, 2, 2))
plot(stl_mensual$time.series[, "trend"], 
     main = "Tendencia - Línea 3", ylab = "Tendencia", col = "steelblue", lwd = 2)
plot(stl_mensual$time.series[, "seasonal"], 
     main = "Estacionalidad - Línea 3", ylab = "Estacional", col = "steelblue", lwd = 2)
plot(stl_mensual$time.series[, "remainder"], 
     main = "Residuos - Línea 3", ylab = "Residuos", col = "steelblue", lwd = 2)
par(mfrow = c(1, 1))

#************************************************************************************************#
# 8. ANÁLISIS DE ESTACIONARIEDAD (PRUEBA ADF) ----
#************************************************************************************************#

cat("\n========================================\n")
cat("8. PRUEBA DE ESTACIONARIEDAD (ADF) - LÍNEA 3\n")
cat("========================================\n")

adf_test <- adf.test(ts_mensual, alternative = "stationary")
print(adf_test)

if (adf_test$p.value < 0.05) {
  cat("\n✅ La serie de Línea 3 ES estacionaria (p < 0.05)\n")
  estacionaria <- TRUE
} else {
  cat("\n❌ La serie de Línea 3 NO es estacionaria (p >= 0.05)\n")
  estacionaria <- FALSE
}
cat("\n")

#************************************************************************************************#
# 9. ANÁLISIS DE AUTOCORRELACIÓN (ACF Y PACF) ----
#************************************************************************************************#

cat("========================================\n")
cat("9. ANÁLISIS DE AUTOCORRELACIÓN - LÍNEA 3\n")
cat("========================================\n")

par(mfrow = c(1, 2))
acf(ts_mensual, main = "ACF - Línea 3", 
    lag.max = 24, col = "steelblue", lwd = 2)
pacf(ts_mensual, main = "PACF - Línea 3", 
     lag.max = 24, col = "steelblue", lwd = 2)
par(mfrow = c(1, 1))

#************************************************************************************************#

# Verificación rápida de la calidad de los datos
cat("\nEstadísticas descriptivas - Línea 3:\n")
cat("  Media diaria:", round(mean(serie_completa$afluencia, na.rm = TRUE)), "usuarios\n")
cat("  Mediana diaria:", round(median(serie_completa$afluencia, na.rm = TRUE)), "usuarios\n")
cat("  Desv. estándar:", round(sd(serie_completa$afluencia, na.rm = TRUE)), "usuarios\n")
cat("  Mínimo:", round(min(serie_completa$afluencia, na.rm = TRUE)), "usuarios\n")
cat("  Máximo:", round(max(serie_completa$afluencia, na.rm = TRUE)), "usuarios\n")

