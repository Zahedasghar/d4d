# Demographic Analysis Using R - Workshop Materials

## 📋 Overview

Complete materials for a hands-on workshop on demographic and health data analysis using R and tidyverse with NHANES data.

---

## 📦 Package Contents

✅ **Main Presentation** - 60+ slide deck with executable code  
✅ **Practice Workbook** - 15+ exercises with solutions  
✅ **Practice Dataset** - 1,000 NHANES observations ready to analyze  
✅ **Complete Documentation** - Setup guides and resources

---

## 🚀 Quick Start

### Install Requirements

```r
install.packages(c("tidyverse", "rio", "modelsummary", "NHANES"))
```

### Render Materials

```bash
quarto render demographic-analysis-nhanes.qmd
quarto render demographic-analysis-workbook.qmd
```

---

## 📚 Workshop Outline (3-4 hours)

1. **Introduction** (30 min) - R basics, NHANES data
2. **Data Exploration** (30 min) - Import, summarize, assess
3. **Data Wrangling** (60 min) - Transform, clean, create indicators
4. **Analysis** (45 min) - Calculate prevalence, patterns, gradients
5. **Visualization** (30 min) - Pyramids, plots, figures
6. **Mini-Project** (30 min) - CV risk profile analysis

---

## 🎯 Learning Objectives

- Import and explore demographic/health datasets
- Clean and transform variables
- Calculate demographic indicators
- Analyze patterns by age, sex, socioeconomic factors
- Create effective visualizations
- Export reproducible results

---

## 📊 Key Topics

**Data Wrangling:** filter, select, mutate, summarise, group_by  
**Demographic Analysis:** Age-sex distributions, prevalence, gradients  
**Health Indicators:** BMI, hypertension, diabetes, risk factors  
**Visualization:** Population pyramids, distributions, comparisons

---

## 💻 Technical Requirements

- R (≥ 4.0.0)
- RStudio (≥ 2023.06)
- Quarto (≥ 1.3)
- Packages: tidyverse, rio, modelsummary, NHANES

---

## 📁 Files

| File | Description |
|------|-------------|
| `demographic-analysis-nhanes.qmd` | Main slide deck |
| `demographic-analysis-workbook.qmd` | Exercise workbook |
| `nhanes_practice_data.csv` | Practice dataset (1000 obs) |
| `create_practice_data.R` | Data generator script |
| `custom-theme.scss` | Presentation styling |

---

## 🔧 Troubleshooting

**Packages won't install?**
```r
install.packages("tidyverse", dependencies = TRUE)
```

**Quarto won't render?**
```bash
quarto check
```

**Data won't load?**
```r
list.files()
read_csv("nhanes_practice_data.csv")
```

---

## 📖 Resources

- [R for Data Science](https://r4ds.hadley.nz/)
- [NHANES Documentation](https://wwwn.cdc.gov/nchs/nhanes/)
- [WHO Indicators](https://www.who.int/data/gho)
- [ggplot2 Book](https://ggplot2-book.org/)

---

## 🎨 Customization

Edit `.qmd` files to:
- Add your logo
- Change colors (edit `.scss`)
- Modify content
- Add local examples

---

## 🤝 For Instructors

**Pre-workshop:** Send setup instructions 1 week ahead  
**During:** Live code, use sticky notes for help, take breaks  
**Post:** Share materials, gather feedback

**Timing:** Don't rush Part 3 (wrangling) - it's foundational

---

## 📝 Citation

```
Demographic Analysis Using R Workshop Materials (2024)
NHANES-based training for population health analysis
```

---

**Happy Learning! 📊✨**

*The best way to learn R is by doing!*
