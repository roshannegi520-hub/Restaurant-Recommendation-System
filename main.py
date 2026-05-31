from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import http.client
import json

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 1. THE "SMART" CONTEXT EXTRACTOR ---
def analyze_context(user_query: str):
    """
    Breaks down a complex user query into a clean API search and context rules.
    Example: "best momo with great ambience and mid budget in ajmer"
    """
    query_lower = user_query.lower()
    
    # Defaults
    min_rating = 0.0
    budget_level = "any" # can be 'cheap', 'mid', 'expensive'
    
    # 1. Detect Sentiment/Rating needs
    if any(word in query_lower for word in ["best", "great", "excellent", "top"]):
        min_rating = 4.0
    
    # 2. Detect Budget Context
    if any(word in query_lower for word in ["cheap", "budget", "affordable", "low cost"]):
        budget_level = "cheap"
    elif any(word in query_lower for word in ["mid budget", "medium", "reasonable"]):
        budget_level = "mid"
    elif any(word in query_lower for word in ["luxury", "expensive", "premium", "5 star"]):
        budget_level = "expensive"
        
    # 3. Clean the query for RapidAPI (remove the fluff words so the API doesn't get confused)
    fluff_words = ["best", "great", "with", "and", "mid", "budget", "ambience", "cheap", "luxury", "in"]
    clean_search_words = [word for word in query_lower.split() if word not in fluff_words]
    clean_api_query = " ".join(clean_search_words)
    
    # If the user only typed fluff, default to a safe search
    if not clean_api_query.strip():
        clean_api_query = "Hotels"

    return clean_api_query, min_rating, budget_level


@app.get("/api/recommendations")
def get_recommendations(location: str = "Dehradun"): 
    
    # --- 2. ANALYZE THE CONTEXT ---
    api_query, required_min_rating, budget_level = analyze_context(location)
    
    # Print to your Python terminal so you can show the examiner!
    print(f"\n--- SMART ANALYSIS ---")
    print(f"User typed: {location}")
    print(f"API Search Term: {api_query}")
    print(f"Context Required - Min Rating: {required_min_rating}, Budget: {budget_level}")
    print(f"----------------------\n")

    conn = http.client.HTTPSConnection("local-business-data.p.rapidapi.com")

    headers = {
        'x-rapidapi-key': "01f4398910msh566de4f945c57eep151cf3jsnaa34bebe4b6c", 
        'x-rapidapi-host': "local-business-data.p.rapidapi.com",
        'Content-Type': "application/json"
    }

    # Format for URL (replace spaces with %20)
    safe_query = api_query.replace(" ", "%20")
    
    # --- THIS IS THE FIX: Uses {safe_query} instead of hardcoding Dehradun ---
    conn.request("GET", f"/search?query={safe_query}&limit=30&language=en&region=us", headers=headers)

    res = conn.getresponse()
    raw_data = res.read()
    
    try:
        json_data = json.loads(raw_data.decode("utf-8"))
        
        if isinstance(json_data, list):
            results = json_data
        else:
            results = json_data.get("data", [])

        smart_list = []
        
        for place in results:
            rating = place.get("rating", 0.0)
            
            # Simulated Budget Filter
            estimated_price = "mid"
            if rating >= 4.5 and place.get("review_count", 0) > 500:
                estimated_price = "expensive"
            elif rating < 3.5:
                estimated_price = "cheap"

            photo_url = place.get("photo_url") or place.get("thumbnail") or "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80"
            
            # --- 3. APPLY CONTEXT RULES ---
            if rating >= required_min_rating:
                if budget_level == "any" or budget_level == estimated_price:
                    smart_list.append({
                        "name": place.get("name", "Unknown Place"),
                        "address": place.get("full_address", place.get("address", "No Address")),
                        "rating": rating,
                        "image": photo_url,
                        "context_tag": f"{estimated_price.title()} Budget" 
                    })
                
        smart_list = sorted(smart_list, key=lambda x: x["rating"], reverse=True)
        return smart_list

    except Exception as e:
        return {"error": f"Data Parsing Error: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)