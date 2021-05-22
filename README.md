# agro_monitor

This QuickApp contains data of accumulated temperature and precipitation, soil temperature and moisture from OpenWeathermap via Agro Monitoring. 

Accumulated temperature and precipitation is essential to make a right decision depends on a threshold setting. Temperature quantity index calculated as the sum of daily temperatures. Humidity quantity index expressed as the sum of daily precipitation. Soil temperature and moisture are essential indices that allow your customer to adjust irrigation work and prevent crop roots damage.

Current soil data is updated 2 times a day. The soil temperature is provided only in Kelvins and in this quickapp converted to Celsius (C = K - 273.15)


IMPORTANT
- You need an API key and Polygon ID from https://agromonitoring.com
- You need to create your Api key and Polygon ID at https://agromonitoring.com/dashboard/dashboard-start
   - After your registration click the "New" button in the top of the "Create polygon" screen.
   - Click on the polygon icon or square icon on the map.
   - Draw your polygon. If you choose a polygon shape icon do not forget to merge the first and last points to finish your polygon.
   - Fill in the "Name" field and click the "Create" button to save your polygon.
- The API is free up to 60 calls per minute and a total area of polygons	of 1000 ha


See: https://agromonitoring.com/dashboard/dashboard-start
See: https://openweathermap.medium.com/dashboard-update-current-and-historical-soil-data-24422fc75c5b


Version 0.1 (22 May 2021)
- Initial version


Variables (mandatory): 
- apiKey = Get your free API key from https://agromonitoring.com
- polygon = Create your Polygon ID at https://agromonitoring.com/dashboard/dashboard-start
- interval = [number] in seconds time to get the data from the API
- timeout = [number] in seconds for http timeout
- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
- icon = [numbber] User defined icon number (add the icon via an other device and lookup the number)
