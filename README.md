# Bellabeat Smart Device Data Analysis
**Author:** Vita Borychevska  
**Tools:** DuckDB SQL, Tableau, MS Excel  

---

### 1. Business Task (Ask)

**About Bellabeat**  
Bellabeat is a wellness company that creates smart devices for women. Their products track daily activity, sleep, stress, and reproductive health to help women build better lifestyle habits.

**The Problem**  
Bellabeat wants to understand how people use smart fitness trackers in their everyday lives. By analyzing usage data from competitor devices, Bellabeat can find clear patterns in activity and sleep to improve its product features and digital marketing strategy.

**Business Objectives**
* Identify key trends in how users track their steps, sleep, and inactive time.
* Group users into practical activity levels.
* Provide clear marketing and product recommendations to the Bellabeat team based on these findings.

**Key Stakeholders**
* **Urška Sršen:** Co-founder and Chief Creative Officer
* **Marketing Team:** Needs data to plan targeted campaigns and improve customer retention.
* **Product Team:** Can use behavioral habits to design better app reminders and user features.

---

### 2. Data Sources (Prepare)

* **Source:** Public Fitbit fitness tracker data from Kaggle (collected via Fitabase).
* **Timeframe:** March 12, 2016 – April 12, 2016.
* **Datasets used:** `dailyActivity_merged.csv` (steps, calories, active minutes) and `minuteSleep_merged.csv` (sleep records).

**Data Limitations**
* **Sample size:** The dataset includes 35 user IDs across 457 rows, with users recording between 8 and 32 days (average: 13.1 days).
* **Missing demographics:** The data does not show user gender or age, which is important to keep in mind since Bellabeat specifically targets women.
* **Data age:** The data is from 2016, so today’s user habits may differ.

---

### 3. Data Cleaning (Process)

I used **DuckDB SQL** to clean and prepare the tables:
* **Null Check:** Scanned all main columns (`Id`, `ActivityDate`, `TotalSteps`, `Calories`); confirmed there were zero missing values.
* **Duplicates:** Checked for duplicate `Id` and `ActivityDate` combinations; found zero duplicate rows.
* **Range Verification:** Confirmed that steps, distance, and calories were positive numbers with no negative errors.
* **Sleep Quality Filter:** Since some users only recorded 1 or 2 sleep logs, I filtered the sleep data to users with at least 10 logged sessions (`COUNT(logId) >= 10`) so that individual averages remained reliable.

---

### 4. Key Findings (Analyze)

#### 1. Most users are in low or moderate activity tiers
Users were grouped based on their daily step average:
* **Low Activity (< 5,000 steps):** 14 users (40%)
* **Moderate Activity (5,000 – 10,000 steps):** 15 users (43%)
* **High Activity (> 10,000 steps):** 6 users (17%)

*Takeaway:* Over 80% of users do not reach the common 10,000-step target. Most users need gentle motivation to move more rather than high-intensity fitness plans.

#### 2. Activity drops sharply on Tuesdays
* **Most active day:** Wednesday (average 7,511 steps).
* **Least active day:** Tuesday (average 4,915 steps).
* Users take roughly **2,600 fewer steps on Tuesday compared to Wednesday**.

#### 3. Users spend most of the day inactive
* Users averaged **995 sedentary minutes per day (~16.6 hours)**.
* While this number includes sleep and non-wearing time, it shows that people spend the majority of their waking hours sitting down.

#### 4. More steps burn more calories, but individual results vary
* There is a **moderate positive correlation** ($r \approx 0.57$) between daily steps and calories burned.
* Activity clearly helps burn energy, but personal traits (like weight and exercise intensity) also play a large role.

#### 5. Higher daily activity does not mean longer sleep
* Users averaged roughly **6 hours of recorded sleep**, which is below the recommended 7–8 hours.
* The correlation between steps and sleep hours was very weak ($r = 0.24$), showing that simply walking more does not automatically lead to more sleep.

---

### 5. Recommendations for Bellabeat (Act)

1. **Send smart notifications on Tuesday**  
Instead of generic daily notifications, send encouraging reminders on Tuesday mornings when activity hits its lowest point of the week. On Wednesday evenings, send a congratulatory message celebrating weekly progress.

2. **Promote "short movement breaks"**  
With users averaging over 16 hours of inactive time per day, position Bellabeat products as friendly desk companions. Introduce silent vibration alerts that prompt users to take a 2-minute walking break if they have been seated for more than an hour.

3. **Build a dedicated Sleep & Rest score**  
Since high step counts do not directly increase sleep, treat sleep as its own wellness focus. Add bedtime reminders and short relaxation audio tracks in the Bellabeat app to help users move closer to the recommended 7–8 hours of rest.

---

### 6. Data Summary Tables

**Table 1: User Activity Segmentation**
| Activity Level | Daily Steps | Users | Share |
| :--- | :--- | :--- | :--- |
| **Low Activity** | Under 5,000 steps | 14 | 40% |
| **Moderate Activity** | 5,000 – 10,000 steps | 15 | 43% |
| **High Activity** | Over 10,000 steps | 6 | 17% |

**Table 2: Activity by Day of the Week**
| Day | Average Steps | Average Calories |
| :--- | :--- | :--- |
| **Wednesday** | 7,511 | 2,377 |
| **Monday** | 7,119 | 2,253 |
| **Saturday** | 7,090 | 2,278 |
| **Thursday** | 6,847 | 2,298 |
| **Friday** | 6,738 | 2,314 |
| **Sunday** | 6,058 | 2,168 |
| **Tuesday** | 4,915 | 1,742 |
