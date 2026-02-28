# Afluencia-Linea-3
# 🚇 Análisis de Series de Tiempo - Afluencia del Metrobús CDMX (2017-2020)

## 📋 Descripción del Proyecto

Este proyecto realiza un análisis exhaustivo de la afluencia diaria del sistema Metrobús de la Ciudad de México durante el período 2017-2020. El análisis aplica técnicas de **series de tiempo** y **detección de outliers** para comprender el comportamiento, patrones estacionales y tendencias del transporte público más importante de la capital mexicana.

El proyecto forma parte de la **Tarea Práctica 1** de la asignatura *Modelos de Supervivencia y Series de Tiempo* de la Facultad de Ciencias, UNAM.

## 🎯 Objetivos

- Limpiar y preparar datos de afluencia del Metrobús (2017-2020)
- Identificar y tratar valores atípicos (outliers) mediante métodos robustos
- Analizar la estacionariedad de la serie de tiempo
- Descomponer la serie en sus componentes: tendencia, estacionalidad y residuos
- Visualizar patrones temporales a diferentes escalas (diaria y mensual)
- Evaluar la autocorrelación para posibles modelos predictivos

## 🛠️ Metodología

### 1. **Limpieza de datos**
   - Filtrado de años 2017-2020
   - Manejo de valores faltantes mediante imputación lineal (`na.approx`)
   - Agregación diaria sumando todas las líneas del Metrobús

### 2. **Detección y tratamiento de outliers**
   - Método STL (Seasonal-Trend decomposition using Loess)
   - Identificación de outliers como residuos > 3 desviaciones estándar
   - Winsorización al 1% y 99% para limitar valores extremos

### 3. **Análisis de series de tiempo**
   - Prueba de Dickey-Fuller Aumentada (ADF) para estacionariedad
   - Funciones de autocorrelación (ACF) y autocorrelación parcial (PACF)
   - Descomposición STL para identificar patrones estacionales
   - Agregación mensual para reducir ruido

### 4. **Visualización**
   - Serie diaria con detección de outliers
   - Comparación diario vs mensual
   - Componentes de tendencia, estacionalidad y residuos

## 📊 Resultados Principales

- **Período analizado:** 1,461 días (2017-2020)
- **Valores imputados:** Identificación y tratamiento de datos faltantes
- **Outliers detectados:** Eventos anómalos en la afluencia diaria
- **Estacionariedad:** Evaluación mediante prueba ADF
- **Patrones estacionales:** Identificación de meses con mayor/menor afluencia
- **Tendencia:** Análisis de crecimiento o decrecimiento en el período

## 🚀 Cómo usar este repositorio

### Requisitos
```r
install.packages(c("zoo", "imputeTS", "ggplot2", "dplyr", 
                   "tidyr", "tseries", "forecast"))
