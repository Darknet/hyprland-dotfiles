#!/bin/bash
# Script de criptomonedas para Waybar

CRYPTO="bitcoin"
CACHE_FILE="/tmp/crypto_cache"
CACHE_TIME=300  # 5 minutos

get_crypto() {
    if [ -f "$CACHE_FILE" ]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [ $cache_age -lt $CACHE_TIME ]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    
    crypto_data=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=${CRYPTO}&vs_currencies=usd&include_24hr_change=true")
    
    if [ $? -eq 0 ] && [ -n "$crypto_data" ]; then
        price=$(echo "$crypto_data" | jq -r ".${CRYPTO}.usd")
        change=$(echo "$crypto_data" | jq -r ".${CRYPTO}.usd_24h_change")
        
        # Formatear precio
        if (( $(echo "$price > 1000" | bc -l) )); then
            price_formatted=$(printf "%.0f" "$price")
        else
            price_formatted=$(printf "%.2f" "$price")
        fi
        
        # Determinar color según cambio
        if (( $(echo "$change > 0" | bc -l) )); then
            change_icon="📈"
            change_formatted=$(printf "+%.2f%%" "$change")
        else
            change_icon="📉"
            change_formatted=$(printf "%.2f%%" "$change")
        fi
        
        result="{\"text\":\"₿ \$${price_formatted}\",\"tooltip\":\"Bitcoin: \$${price_formatted}\\nCambio 24h: ${change_formatted} ${change_icon}\"}"
        echo "$result" > "$CACHE_FILE"
        echo "$result"
    else
        echo "{\"text\":\"₿ Error\",\"tooltip\":\"Error obteniendo datos de crypto\"}"
    fi
}

get_crypto
