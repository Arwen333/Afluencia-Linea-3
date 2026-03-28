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

A continuación, se describen los principales entregables que componen este análisis de la **Línea 3 del Metrobús CDMX**, incluyendo el código fuente, los datos y el reporte generado.

| Entregable | Descripción | Formato / Archivo | Enlace Directo |
|:---|:---|:---|:---|
| **💻 Script de Análisis** | Código fuente en R que realiza todo el proceso: carga de datos, filtrado de la Línea 3, imputación lineal de valores faltantes, detección de outliers mediante STL, winsorización, agregación mensual, descomposición de la serie, pruebas de estacionariedad (ADF) y generación de visualizaciones (ACF, PACF, series diarias y mensuales). | `R Script` | [🔗 Ver Código](https://raw.githubusercontent.com/Arwen333/Afluencia-Linea-3/refs/heads/main/Analisis%20Afluencia.R) |
| **📊 Datos Analizados** | Conjunto de datos original de afluencia del Metrobús. El script procesa este archivo para filtrar y analizar específicamente los datos de la Línea 3 en el período 2017-2020, creando las series diarias y mensuales utilizadas en el análisis. | `CSV` | [🔗 Ver Datos](https://raw.githubusercontent.com/Arwen333/Afluencia-Linea-3/refs/heads/main/afluenciamb_simple_01_2026.csv) |
| **📈 Reporte Generado** | Documento PDF que presenta los resultados del análisis de la Línea 3. Incluye todas las gráficas generadas (serie diaria con outliers, comparativa diario vs. mensual, componentes de tendencia y estacionalidad, y funciones de autocorrelación ACF/PACF) junto con la interpretación de los hallazgos y las conclusiones del estudio. | `PDF` | [🔗 Ver Reporte](https://github.com/Arwen333/Afluencia-Linea-3/blob/main/An%C3%A1lis-de-Series-de-Tiempo.pdf) |


## 📬 Contacto
Autor: Arwen Yetzirah Ortiz N.
Fecha de creación: 26/02/2026
Última actualización: 28/03/2026
Email: arwenort@ciencias.unam.mx
Institución: Facultad de Ciencias, Universidad Nacional Autónoma de México (UNAM)
Asignatura: Modelos de Supervivencia y Series de Tiempo

