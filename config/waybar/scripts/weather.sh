#!/bin/bash
# Script de clima para Waybar

CITY="Barcelona"
API_KEY="tu_api_key_aqui"  # Obtener de openweathermap.org
CACHE_FILE="/tmp/weather_cache"
CACHE_TIME=1800  # 30 minutos

get_weather() {
    if [ -f "$CACHE_FILE" ]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [ $cache_age -lt $CACHE_TIME ]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    
    if [ -z "$API_KEY" ] || [ "$API_KEY" = "tu_api_key_aqui" ]; then
        echo "{\"text\":\"🌤️ N/A\",\"tooltip\":\"Configurar API key en weather.sh\"}"
        return
    fi
    
    weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=metric&lang=es")
    
    if [ $? -eq 0 ] && [ -n "$weather_data" ]; then
        temp=$(echo "$weather_data" | jq -r '.main.temp' | cut -d'.' -f1)
        desc=$(echo "$weather_data" | jq -r '.weather[0].description')
        humidity=$(echo "$weather_data" | jq -r '.main.humidity')
        feels_like=$(echo "$weather_data" | jq -r '.main.feels_like' | cut -d'.' -f1)
        
        # Iconos según el clima
        weather_id=$(echo "$weather_data" | jq -r '.weather[0].id')
        case $weather_id in
            2*) icon="⛈️" ;;
            3*) icon="🌦️" ;;
            5*) icon="🌧️" ;;
            6*) icon="❄️" ;;
            7*) icon="🌫️" ;;
            800) icon="☀️" ;;
            80*) icon="☁️" ;;
            *) icon="🌤️" ;;
        esac
        
        result="{\"text\":\"${icon} ${temp}°C\",\"tooltip\":\"${CITY}: ${desc}\\nTemperatura: ${temp}°C (sensación ${feels_like}°C)\\nHumedad: ${humidity}%\"}"
        echo "$result" > "$CACHE_FILE"
        echo "$result"
    else
        echo "{\"text\":\"🌤️ Error\",\"tooltip\":\"Error obteniendo datos del clima\"}"
    fi
}

get_weather
