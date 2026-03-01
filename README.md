# Afluencia-Linea-3
# 🚇 Análisis de Series de Tiempo - Afluencia del Metrobús CDMX (2017-2020)

## 📋 Descripción del Proyecto

Este proyecto realiza un análisis exhaustivo de la afluencia diaria del sistema Metrobús de la Ciudad de México, específicamente de la **Línea 3**, durante el período 2017-2020. El análisis aplica técnicas de **series de tiempo** y **detección de outliers** para comprender el comportamiento, patrones estacionales y tendencias de una de las rutas de transporte público más importantes de la capital mexicana.

El proyecto forma parte de la **Tarea Práctica 1** de la asignatura *Modelos de Supervivencia y Series de Tiempo* de la Facultad de Ciencias, UNAM.

## 🎯 Objetivos

- Limpiar y preparar datos de afluencia del Metrobús (2017-2020), enfocándose en la **Línea 3**.
- Identificar y tratar valores atípicos (outliers) mediante métodos robustos.
- Analizar la estacionariedad de la serie de tiempo.
- Descomponer la serie en sus componentes: tendencia, estacionalidad y residuos.
- Visualizar patrones temporales a diferentes escalas (diaria y mensual).
- Evaluar la autocorrelación para posibles modelos predictivos.

## 🛠️ Metodología

### 1. **Limpieza de datos**
   - Filtrado de años 2017-2020 y selección de la **Línea 3**.
   - Manejo de valores faltantes mediante imputación lineal (`na.approx`).
   - Completado de la serie diaria para tener un registro continuo.

### 2. **Detección y tratamiento de outliers**
   - Método STL (Seasonal-Trend decomposition using Loess) con opción robusta.
   - Identificación de outliers como residuos > 3 desviaciones estándar.
   - Winsorización al 1% y 99% para limitar valores extremos.

### 3. **Análisis de series de tiempo**
   - Prueba de Dickey-Fuller Aumentada (ADF) para estacionariedad.
   - Funciones de autocorrelación (ACF) y autocorrelación parcial (PACF).
   - Descomposición STL para identificar patrones estacionales.
   - Agregación mensual para reducir ruido y observar tendencias de fondo.

### 4. **Visualización**
   - Serie diaria con detección de outliers.
   - Comparación diario vs mensual.
   - Componentes de tendencia, estacionalidad y residuos.

## 📊 Resultados Principales

- **Período analizado:** 1,461 días (2017-2020) para la **Línea 3**.
- **Valores imputados:** Identificación y tratamiento de datos faltantes en la serie diaria.
- **Outliers detectados:** Eventos anómalos en la afluencia diaria, posiblemente asociados a fines de semana, días festivos o contingencias.
- **Estacionariedad:** Evaluación mediante prueba ADF sobre la serie mensual.
- **Patrones estacionales:** Identificación de meses con mayor/menor afluencia y estacionalidad intra-semanal.
- **Tendencia:** Análisis de crecimiento o decrecimiento en el período.

## 📁 Entregables del Proyecto

### 💻 Código Fuente
El script principal que realiza todo el análisis:

```r
# Script: Análisis de Afluencia - Línea 3 del Metrobús CDMX
# Autor: Arwen Yetzirah Ortiz N.
# Descripción: Realiza limpieza, imputación, detección de outliers,
#              análisis de estacionariedad, descomposición STL y visualizaciones

# Carga de librerías
library(zoo)
library(imputeTS)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tseries)
library(forecast)

# Cargar datos desde GitHub
url_github <- "https://raw.githubusercontent.com/Arwen333/Afluencia-Linea-3/refs/heads/main/afluenciamb_simple_01_2026.csv"
df <- read.csv(url_github, encoding = "UTF-8", stringsAsFactors = FALSE)

# Filtrar Línea 3 y período 2017-2020
df_linea3 <- df %>%
  filter(linea == "Línea 3", anio >= 2017, anio <= 2020)

# Crear serie diaria completa
fechas_completas <- data.frame(fecha = seq(min(df_linea3$fecha), 
                                           max(df_linea3$fecha), 
                                           by = "day"))
serie_diaria <- merge(fechas_completas, df_linea3[, c("fecha", "afluencia")], 
                      by = "fecha", all.x = TRUE)

# Imputación de valores faltantes
serie_diaria$afluencia <- na.approx(serie_diaria$afluencia)

# Detección de outliers con STL
ts_diaria <- ts(serie_diaria$afluencia, frequency = 365)
stl_fit <- stl(ts_diaria, s.window = "periodic", robust = TRUE)
residuos <- stl_fit$time.series[, "remainder"]
limite <- 3 * sd(residuos, na.rm = TRUE)
serie_diaria$outlier <- abs(residuos) > limite

# Winsorización
p1 <- quantile(serie_diaria$afluencia, 0.01)
p99 <- quantile(serie_diaria$afluencia, 0.99)
serie_diaria$afluencia <- pmax(pmin(serie_diaria$afluencia, p99), p1)

# Agregación mensual
serie_mensual <- serie_diaria %>%
  mutate(mes = as.Date(format(fecha, "%Y-%m-01"))) %>%
  group_by(mes) %>%
  summarise(afluencia = mean(afluencia))

# Prueba de estacionariedad ADF
ts_mensual <- ts(serie_mensual$afluencia, frequency = 12, 
                 start = c(2017, 1))
adf.test(ts_mensual)

# Generar visualizaciones
# ... (código de gráficos)
