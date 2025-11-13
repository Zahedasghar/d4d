# Instructor Guide: Demographic Analysis Using R Workshop

## 🎓 Workshop Overview

**Target Audience:** Researchers, students, practitioners in demography, public health, social sciences  
**Level:** Beginner to Intermediate R users  
**Duration:** 3-4 hours (flexible)  
**Format:** Hands-on with live coding

---

## 📋 Pre-Workshop Checklist

### 1 Week Before

- [ ] Send installation instructions to participants
- [ ] Share system requirements
- [ ] Provide pre-workshop survey (assess R experience)
- [ ] Test all code on Windows/Mac/Linux
- [ ] Prepare troubleshooting FAQ

### 3 Days Before

- [ ] Send reminder email with Zoom link (if online)
- [ ] Share practice dataset for early birds
- [ ] Prepare backup plans for technical issues
- [ ] Review participant survey responses

### Day Before

- [ ] Test screen sharing and presentation
- [ ] Prepare sticky note system (or digital equivalent)
- [ ] Review timing and identify optional sections
- [ ] Prepare ice breaker activity

### Day Of

- [ ] Arrive 15 min early (or open Zoom room)
- [ ] Test all technology
- [ ] Welcome participants as they arrive
- [ ] Start on time!

---

## ⏱️ Detailed Timing Guide

### Part 1: Introduction (30 min)

**0:00-0:05** - Welcome & Logistics
- Introduce yourself
- Workshop goals
- How to ask for help (sticky notes/chat)
- Bathroom/break information

**0:05-0:10** - Ice Breaker
- Quick introductions (if small group)
- Poll: R experience level
- Poll: Research interests

**0:10-0:20** - Why R for Demographic Analysis?
- Show impressive examples
- Discuss reproducibility
- Compare to other tools (SPSS, Stata, Excel)

**0:20-0:30** - NHANES Introduction
- What is NHANES?
- Why useful for learning?
- Variables we'll use

**Teaching Tips:**
- Keep energy high at the start
- Show exciting visualizations
- Be honest about learning curve
- Share your own learning journey

---

### Part 2: Data Exploration (30 min)

**0:30-0:40** - Setup & Import
- Live code loading packages
- Import NHANES data
- Common errors to watch for

**0:40-0:50** - Initial Exploration
- glimpse(), summary(), head()
- Discuss each variable
- Check for missing data

**0:50-1:00** - First Exercise
- Participants explore data independently
- Circulate to help
- Share interesting findings

**Teaching Tips:**
- Code slowly - people are typing along
- Explain every line
- Show how to read error messages
- Celebrate mistakes as learning

**Common Issues:**
- Typos in function names
- Forgetting to load packages
- Wrong working directory

---

### Part 3: Data Wrangling (60 min) ⭐ CRITICAL

**1:00-1:15** - Creating Variables
- Age groups (live code together)
- BMI categories (they try, you help)
- Hypertension indicator (pair programming)

**1:15-1:30** - The Pipe Operator
- Explain concept with physical example
- Simple examples building complexity
- Practice reading pipes aloud

**1:30-1:45** - Core dplyr Verbs
- filter() - show multiple examples
- select() - demonstrate helpers
- mutate() - create new variables

**Break: 1:45-2:00** ☕
- Encourage stretch, chat, troubleshoot

**2:00-2:15** - More dplyr
- summarise() vs pull()
- group_by() - the game changer!
- arrange() - sort results

**2:15-2:30** - Putting It Together
- Multi-step pipeline
- Real analysis example
- Participants replicate

**Teaching Tips:**
- This is THE most important section
- Don't rush - master basics
- Use physical metaphors (assembly line)
- Live code, make intentional mistakes
- Show your thought process

**Common Issues:**
- Forgetting group_by() 
- Not using pull() before base R functions
- Piping confusion
- Case sensitivity

---

### Part 4: Analysis (45 min)

**2:30-2:45** - Descriptive Analysis
- Age-sex distributions
- Prevalence calculations
- Group comparisons

**2:45-3:00** - Advanced Patterns
- Multiple grouping variables
- Socioeconomic gradients
- Creating summary tables

**3:00-3:15** - Hands-on Exercise
- Participants analyze independently
- You circulate and assist
- Share solutions

**Teaching Tips:**
- Connect to demographic theory
- Discuss public health implications
- Encourage interpretation, not just code
- Ask "what does this mean?"

---

### Part 5: Visualization (30 min)

**3:15-3:25** - ggplot2 Basics
- Grammar of graphics concept
- Population pyramid example
- Modify together

**3:25-3:35** - More Visualizations
- Distributions, trends, comparisons
- Color choices
- Labels and themes

**3:35-3:45** - Participants Create Plots
- Choose their own variable
- Share screens (if virtual)
- Gallery walk (if in-person)

**Teaching Tips:**
- Emphasize clear communication
- Discuss chart choice rationale
- Show both good and bad examples
- Make it fun!

---

### Part 6: Mini-Project (30 min)

**3:45-4:05** - CV Risk Profile
- Explain project goal
- Work in pairs/small groups
- You circulate, provide hints

**4:05-4:15** - Share Results
- Groups present findings
- Discuss different approaches
- Celebrate successes

**4:15-4:30** - Wrap-up & Q&A
- Review key concepts
- Next steps in learning
- Resources
- Feedback form

**Teaching Tips:**
- Make it collaborative
- Praise effort and creativity
- No "wrong" approaches
- End on high note!

---

## 🎯 Key Learning Outcomes by Section

### Must Understand
- Pipe operator logic
- filter() and select()
- mutate() for new variables
- group_by() + summarise() pattern

### Should Understand
- Data types (numeric, factor, character)
- Missing data handling
- Basic ggplot2 structure
- Exporting results

### Nice to Understand
- Advanced dplyr functions
- Age standardization concepts
- Complex visualizations
- Reproducible workflows

---

## 🚨 Common Participant Challenges

### Challenge 1: Pipe Confusion

**Symptom:** "I don't understand what `%>%` does"

**Solution:**
```r
# Show both ways
mean(data$variable)

data %>% pull(variable) %>% mean()

# Use physical metaphor
# "Take data, THEN select column, THEN calculate mean"
```

### Challenge 2: group_by() Mysteries

**Symptom:** "Why isn't my calculation working by group?"

**Solution:**
- Show grouped vs ungrouped side-by-side
- Physically group people in room by characteristic
- Always ungroup() at end

### Challenge 3: ggplot Syntax

**Symptom:** "Why won't my plot show?"

**Solution:**
- Check for `+` not `%>%`
- Ensure data is piped correctly
- Start simple, add layers

### Challenge 4: Missing Data Frustration

**Symptom:** "I get NA for everything!"

**Solution:**
- Explain why data is missing
- Show `na.rm = TRUE` option
- Discuss when to exclude vs impute

---

## 💡 Teaching Strategies

### Active Learning Techniques

1. **Think-Pair-Share**
   - Pose question
   - Think individually (1 min)
   - Discuss with neighbor (2 min)
   - Share with group

2. **Live Coding**
   - Type while explaining
   - Make deliberate mistakes
   - Fix errors together
   - Narrate your thinking

3. **Pair Programming**
   - One person codes, one navigates
   - Switch roles
   - Discuss approach

4. **Gallery Walk** (in-person)
   - Post visualizations around room
   - Participants tour and discuss
   - Vote on favorites

### Engagement Strategies

- **Polls/Quizzes:** Quick checks for understanding
- **Sticky Notes:** Red = help needed, Green = good to go
- **Chat (virtual):** Backchannel for questions
- **Breaks:** Every 45-60 minutes minimum

### Inclusive Teaching

- Use gender-neutral examples
- Vary cultural references
- Provide multiple ways to engage
- Acknowledge different starting points
- Celebrate diverse backgrounds

---

## 🔧 Technical Troubleshooting

### Setup Issues

**Problem:** Packages won't install

```r
# Solutions
update.packages()
install.packages("tidyverse", dependencies = TRUE)

# If corporate firewall
options(download.file.method = "wininet")
```

**Problem:** Quarto won't render

```bash
quarto check
quarto install tinytex  # For PDF
```

**Problem:** Can't find data file

```r
# Check working directory
getwd()

# List files
list.files()

# Set if needed (but explain R Projects better!)
setwd("path/to/files")
```

### During Workshop Issues

**Problem:** Screen too small to see

- Increase font size (Cmd/Ctrl + Plus)
- Use Zoom controls
- Share code in chat

**Problem:** Code breaks for one person

- Check typos
- Verify package versions
- Use fresh R session
- Copy/paste from working code

---

## 📊 Assessment Ideas

### Formative (During Workshop)

- Quick polls on key concepts
- Code-along checkpoints
- Pair-share discussions
- Exercise completion

### Summative (End of Workshop)

- Mini-project completion
- Challenge problems
- Reflection questions
- Post-workshop survey

### Follow-up (1-2 weeks later)

- Application to own data
- Optional advanced exercises
- Office hours
- Online community

---

## 📝 Facilitator's Notes

### Flexible Timing

**If running short on time:**
- Skip detailed age standardization
- Reduce number of visualizations
- Shorten mini-project
- Make advanced exercises optional

**If extra time:**
- Add DHS/MICS examples
- Discuss survey weights
- Cover joining datasets
- Introduce purrr for iteration

### Difficulty Adjustment

**For beginners:**
- More scaffolding
- Simpler exercises
- More time on basics
- Pair programming

**For advanced:**
- Faster pace on basics
- More challenge problems
- Introduce advanced topics
- Encourage experimentation

---

## 🎬 Opening Script

> "Good morning everyone! Welcome to Demographic Analysis Using R. I'm [Name] and I'm excited to spend the next [X] hours with you learning how to analyze population health data using modern R tools.
> 
> Today we'll work with real data from NHANES - the same data public health researchers use worldwide. By the end, you'll be able to import, clean, analyze, and visualize demographic data, and create fully reproducible reports.
> 
> A few logistics: [bathrooms, breaks, asking for help, etc.]
> 
> Before we dive in, let's get to know each other a bit..."

---

## 🏁 Closing Script

> "Fantastic work today everyone! You've learned a LOT - from basic data wrangling to creating population pyramids and analyzing health inequalities.
> 
> Remember, learning R is a journey. You won't remember everything, and that's okay. What matters is you know where to look things up, and you have the confidence to try.
> 
> All materials are yours to keep. Practice with your own data, join the R community, and don't hesitate to reach out with questions.
> 
> Before you go, please fill out the feedback form - it helps me improve future workshops.
> 
> Thank you, and happy coding!"

---

## 📚 Additional Resources for Instructors

### Teaching R Resources

- [RStudio Education](https://education.rstudio.com/)
- [Teaching Statistics](https://teachdatascience.com/)
- [Greg Wilson's Teaching Tech Together](https://teachtogether.tech/)

### Community Building

- Start a local R User Group
- Create Slack/Discord channel
- Host regular office hours
- Share on social media (#rstats)

### Continuous Improvement

- Collect feedback after each workshop
- Update materials regularly
- Incorporate new packages/methods
- Share what works with other instructors

---

## ✅ Post-Workshop Checklist

- [ ] Send thank you email with materials
- [ ] Share slides and code
- [ ] Provide certificate (if applicable)
- [ ] Send feedback survey
- [ ] Respond to follow-up questions
- [ ] Update materials based on feedback
- [ ] Share success stories
- [ ] Plan follow-up sessions

---

**Good luck with your workshop! You've got this! 🎉**

*Remember: Your enthusiasm is contagious. Have fun, and your participants will too!*
