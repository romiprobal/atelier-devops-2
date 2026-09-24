import os
import redis
from flask import Flask, jsonify

app = Flask(__name__)

ALERT_THRESHOLD = 25


def alert_threshold():
    """Seuil d'alerte au-dessus duquel une notification est declenchee."""
    return ALERT_THRESHOLD


def sanitize_input(value):
    """Echappe les caracteres dangereux d'une entree utilisateur."""
    return value.replace("<", "&lt;").replace(">", "&gt;")


# Fonction pour initialiser et récupérer le client Redis
def get_redis_client():
    redis_host = os.getenv("REDIS_HOST", "localhost")
    return redis.Redis(host=redis_host, port=6379, decode_responses=True)


@app.route("/health")
def health():
    try:
        client = get_redis_client()
        # Test réel de la dépendance Redis avec un PING
        if client.ping():
            return jsonify(status="ok", redis="connected"), 200
    except Exception as e:
        # En cas d'échec (Redis coupé, injoignable, etc.), on renvoie un code 503
        return jsonify(status="error", redis=str(e)), 503

    return jsonify(status="error", redis="unreachable"), 503


@app.route("/status")
def status():
    return jsonify(service="projet-devops-groupe-demo", version="1.0"), 200


# Ajout de l'endpoint /visits connecté à Redis (Étape 5)
@app.route("/visits")
def visits():
    try:
        client = get_redis_client()
        # Incrémente la clé 'visits' dans Redis de 1 à chaque appel
        count = client.incr("visits")
        return jsonify(visits=count), 200
    except Exception as e:
        return jsonify(error=str(e)), 500


if __name__ == "__main__":
    app.run(debug=True)