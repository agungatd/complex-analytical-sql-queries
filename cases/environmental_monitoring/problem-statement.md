# Environmental monitoring across multiple research stations

## ERD Source data

## Objectives

This query will track air quality metrics, weather patterns, and research team activities with multiple transformations and joins.

## Solution

Explanation of Each CTE

1. StationBase
    - Purpose: Creates a foundational dataset of active environmental stations.
    - Details: Uses ROW_NUMBER() to get the most recent station metadata, filters for active stations updated in the last 12 months.
    - Best Practice: Establishes a clean base layer with deduplication using window functions.
2. AirQualityMetrics
    - Purpose: Aggregates daily air quality measurements (PM2.5, CO2, temperature).
    - Details: Calculates averages, maximums, and counts suspect readings over the past 30 days, joining with StationBase.
    - Best Practice: Uses DATE_TRUNC for consistent time grouping and includes quality metrics for data reliability.
3. WeatherPatterns
    - Purpose: Summarizes weather data with wind direction categorization.
    - Details: Aggregates wind speed and precipitation, transforms wind direction into quadrants (NE, SE, SW, NW) over 30 days.
    - Best Practice: Employs CASE statement for readable categorization and LEFT JOIN to preserve all station data.
4. TeamActivity
    - Purpose: Tracks researcher activities at stations on a weekly basis.
    - Details: Counts unique researchers, total hours, and calibration events over 3 months, grouped by week.
    - Best Practice: Uses conditional counting for specific event types and weekly aggregation for trend analysis.
5. CombinedMetrics
    - Purpose: Integrates all previous CTEs into a comprehensive view.
    - Details: Joins air quality, weather, and team data, calculates suspect reading percentage, and ranks PM2.5 levels per station.
    - Best Practice: Combines multiple data sources with appropriate join types (INNER/LEFT) and adds analytical ranking.
6. Final Query
Applies additional filtering (top 3 PM2.5 ranks or high CO2) and adds a status flag based on suspect readings and calibration events.
Orders results for easy interpretation by station and date.
