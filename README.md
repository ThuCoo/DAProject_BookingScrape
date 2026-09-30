<h1> Data Analysis Project on Booking.com's Scrapes </h1>

**Disclaimer**: \
This project and the associated dataset are strictly for educational and portfolio purposes. \
The data was collected to demonstrate SQL and market analysis skills. Web scraping major platforms may violate their Terms of Service. \
This project is not intended for commercial use, and anyone conducting web scraping should review Booking.com’s robots.txt and Terms of Service beforehand.

<h2> Project Summary </h2>
This project scrapes Booking.com's London properties data to analyze property pricing, geographic distribution, customer sentiment, and temporal trends to uncover competitive market insights.

<h2> Problem Statement </h2>

Launching a new short-term rental on Booking.com without historical data often leads to "guesswork pricing", resulting in either vacant calendars or leaving money on the table. \
As a prospective property owner in London, granular visibility into localized supply density, daily price fluctuations, and competitor performance is needed to build a data-backed launch strategy, optimize initial pricing, and identify exactly what drives top-tier guest ratings in target borough.

<h2> Tools Used </h2>

- **Python** - Data Scraping, Preparation and Modeling.
- **MS SQL Server** - Data Analysis.
- **Tableau** - Visualization and insights.
- **VS Code** - Development environment.

<h2> Scraping Data using Python + Selenium </h2>
Executed 7 automated scraping sessions across the week <i>(Check In Date from 13/10/2026 to 19/10/2026)</i> to capture temporal pricing and availability variations.

- **Target Setup**: Defined check-in dates 14 days in advance and built search parameters for London properties.
- **Automated Navigation**: Used Selenium WebDriver to bypass sign-in modals and continuously clicked "_Load more results_" to capture full search pagination.
- **Data Extraction**: Parsed property cards to extract URLs, names, locations, prices, and review ratings.
- **Export**: Saved the raw extracted dataset to a CSV file.

<h2> Dataset Summary </h2>

Rows: 6,885

Columns: 13 (Cleaned)

Key features:

- **Property Info**: URL, Name, Property ID, Search URL.
- **Location**: Borough, City.
- **Pricing & Booking**: Price (USD), Check-In Date, Check-In Weekday.
- **Ratings**: Score, Rating Category, Total Reviews. Metadata: Scraped At.

<h2> Exploratory Data Analysis using Python </h2>

**Data Loading**: Import scraped dataset using pandas.

**Data Cleaning**: Drop duplicate rows based on URL to ensure unique listings.

**Column Standardization**: Renamed all columns to lowercase.

**Feature Engineering**:

- Extract property_id directly from the URL string.
- Split location into borough and city, handling edge cases where only the city is listed.
- Split raw text ratings into distinct score, rating, and reviews columns.
- Clean text characters from price and reviews and convert them to numeric data types.
- Generate check_in_weekday extracted from the check-in date.
- Categorize ratings for properties with scores below 7.
- Missing Data Handling: Fill NULL values for reviews (0), scores (0), ratings ('No Reviews'), and boroughs ('Unknown').

**Data Consistency Check**: Drop transitional and redundant columns (ratings, score_text, location).

**Database Integration**: Connect to MS SQL Server using SQLAlchemy and append the cleaned dataset to the bookings table.

<h2> Data Analysis using SQL </h2>

1. **Property Distribution** - Count total properties available in each borough.
   |borough |total_properties|
   |--------------|----------------|
   |Acton |1 |
   |Brent |36 |
   |Camden |230 |
   |Chiswick |5 |
   |City of London|54 |
   |... |... |

2. **Price Range by Borough** - Calculate minimum, maximum, average, and median prices partitioned by borough.
   |borough |min_price|avg_price|median_price|max_price|
   |--------------|---------|---------|------------|---------|
   |Acton |164 |164.00 |164 |164 |
   |Brent |66 |182.68 |120 |1181 |
   |Camden |50 |282.78 |241 |1374 |
   |Chiswick |106 |208.04 |203 |375 |
   |City of London|99 |405.96 |344 |1655 |
   |...|... |... |... |... |

3. **Pricing Segments** - Group properties into categorical price ranges and measure property volume per segment.
   |price_range |total_properties|
   |--------------|----------------|
   |0-299 |1278 |
   |300-599 |400 |
   |600-899 |56 |
   |900+ |18 |

4. **Pricing Over Time** - Analyze minimum, average, and maximum prices grouped by check-in date.
   |borough |check_in_date|min_price|avg_price|max_price|
   |--------------|-------------|---------|---------|---------|
   |Acton |2026-10-17 |164 |164 |164 |
   |Brent |2026-10-13 |77 |149.55 |326 |
   |Brent |2026-10-14 |80 |155.47 |368 |
   |Brent |2026-10-15 |83 |172.11 |433 |
   |Brent |2026-10-16 |93 |202.32 |494 |
   |... |... |... |... |... |

5. **Weekday Price Variations** - Calculate average prices throughout the week per borough to identify booking trends.
   |borough |check_in_weekday|avg_price|
   |--------------|----------------|---------|
   |Acton |Saturday |164 |
   |Brent |Monday |122 |
   |Brent |Tuesday |149.55 |
   |Brent |Wednesday |155.47 |
   |Brent |Thursday |172.11 |
   |... |... |... |

6. **Rating Category Comparison** - Compare average scores, prices, and review volumes across different rating categories.
   |rating |avg_score|avg_price|avg_reviews|
   |--------------|---------|---------|-----------|
   |Exceptional |9.76 |319.23 |127.18 |
   |Wonderful |9.15 |400.9 |872.59 |
   |Excellent |8.73 |361.38 |2134.41 |
   |Very Good |8.24 |282.76 |2556.81 |
   |Good |7.49 |218.43 |2116.57 |
   |... |... |... |... |

7. **Top-Rated Properties** - Rank and identify the top 3 highest-rated properties (with >50 reviews) per borough.
   |borough |name|score|reviews|prop_avg_price|
   |--------------|----|-----|-------|--------------|
   |Brent |Large Double Bedroom 10 minutes to Central London|9.6 |84 |102 |
   |Brent |StarNest Willesden Junction|9.3 |91 |142 |
   |Brent |Flat in blue plaque building|8.9 |104 |114 |
   |Camden |The Old Farmhouse Pub and Rooms|9.4 |279 |259 |
   |Camden |Xylo Apartments - Kentish Town|9.3 |267 |393 |
   |... |...|... |... |... |

8. **Value Opportunities** - Identify properties with good ratings (>7) that are priced below their borough's average.
   |property_id |name|price|score |
   |--------------|----|-----|-------|
   |centrally-located-comfortable-room-in-london|Centrally Located Comfortable Room in London|55 |9.3 |
   |baraka-altmore|Baraka Altmore|55 |7.7 |
   |charming-stay-near-london-eye-amp-westminster|Charming Stay Near London Eye & Westminster|61 |9 |
   |zozy-clitterhouse|Zozy Clitterhouse|61 |7.8 |
   |london-victoria-15-minutes-away|London Victoria 15 minutes away|62 |8.6 |
   |... |...|... |... |

<h2> Dashboard using Tableau </h2>

![Dashboard](dashboard.png)

[Tableau Link](https://public.tableau.com/views/DAProject-Bookings/Dashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

<h2> Business Recommendations </h2>

- **Penetration Pricing for Launch**: Launch with rates 15–20% below the borough average to maximize initial bookings and secure the first few positive reviews. Once top-tier ratings are established, scale prices up to capture good rating properties' price difference.

- **Dynamic Weekday Pricing**: Automate base rates to increase mid-week to capture weekend demand.

- **Direct Competitor Benchmarking**: Audit the top 3 highest-rated properties in the target borough to identify and replicate the specific amenities that drive high rating scores, justifying a premium price.

- **Differentiating Against Value Competitors**: Counter highly-rated but underpriced properties by audit their listing trade-offs and market owned listing's key differentiators to sway guests into paying a modest premium for greater comfort.

<h2> Self Reflection and Future Workthrough </h2>

- Scraping still need work, maybe scrape at a deeper level.
- Could be better if having more datas: seeing the differences between normal days and holidays, seeing booking trends, etc.
- Need more woking with doing analysis with data of same properties but different scrape times.
- Should have mapped price range on data cleaning phase(?).
