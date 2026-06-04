# 📦 Freemopay API v2 — Documentation complète
> **Version :** v2  
> **Base URL :** `https://api-v2.freemopay.com`  
> **Format :** JSON  
> **Encodage :** UTF-8
---
## Table des matières
1. [Introduction](#introduction)
2. [Authentification](#authentification)
3. [Rate Limiting](#rate-limiting)
4. [Flux de statut](#flux-de-statut)
5. [Endpoints](#endpoints)
   - [POST /api/v2/payment/token — Générer un token](#1-post-apiv2paymenttoken--générer-un-token)
   - [GET /api/v2/payment/:reference — Statut (Bearer)](#2-get-apiv2paymentreference--statut-avec-bearer-token)
   - [GET /api/v2/payment/:reference — Statut (Basic Auth)](#3-get-apiv2paymentreference--statut-avec-basic-auth)
   - [POST /api/v2/payment — Init paiement (Bearer)](#4-post-apiv2payment--initialiser-un-paiement-avec-bearer-token)
   - [POST /api/v2/payment — Init paiement (Basic Auth)](#5-post-apiv2payment--initialiser-un-paiement-avec-basic-auth)
   - [POST Callback — Notification webhook](#6-post-callback--notification-webhook-marchand)
   - [POST /api/v2/payment/direct-withdraw — Retrait](#7-post-apiv2paymentdirect-withdraw--initier-un-retrait)
6. [Codes de statut des transactions](#codes-de-statut-des-transactions)
7. [Codes d'erreur HTTP](#codes-derreur-http)
---
## Introduction
L'API **Freemopay v2** permet aux marchands d'encaisser des fonds de particuliers via **Mobile Money** ou **Orange Money**.
### Endpoints exposés
| Méthode  | Endpoint                              | Description                                      |
|----------|---------------------------------------|--------------------------------------------------|
| `POST`   | `/api/v2/payment/token`               | Générer un Bearer Token JWT                      |
| `GET`    | `/api/v2/payment/:reference`          | Récupérer le statut d'un paiement                |
| `POST`   | `/api/v2/payment`                     | Initialiser un paiement (encaissement)           |
| `POST`   | `/api/v2/payment/direct-withdraw`     | Initier un retrait (cashout)                     |
| `POST`   | `https://votresite.com/webhook/...`   | Callback reçu par le marchand après transaction  |
---
## Authentification
Deux méthodes sont disponibles et interchangeables selon les endpoints :
### 🔑 Basic Auth
Utilise les identifiants API du compte marchand directement dans l'en-tête HTTP.
```
Authorization: Basic base64(appKey:secretKey)
```
| Paramètre   | Description              |
|-------------|--------------------------|
| `appKey`    | Clé publique de l'application |
| `secretKey` | Clé secrète de l'application  |
### 🪙 Bearer Token (JWT)
Jeton JWT à durée limitée, obtenu via l'endpoint `/api/v2/payment/token`.
```
Authorization: Bearer <access_token>
```
| Propriété   | Valeur        |
|-------------|---------------|
| Algorithme  | HS256 (JWT)   |
| Durée de vie | **3600 secondes** (1 heure) |
> ⚠️ Le token expire après 3600 secondes. Il faut en regénérer un nouveau après expiration.
---
## Rate Limiting
| Limite              | Valeur                          |
|---------------------|---------------------------------|
| Requêtes autorisées | **100 requêtes par minute** par compte marchand |
| Code de réponse     | `429 Too Many Requests`         |
| En-tête de réponse  | `Retry-After: <délai en secondes>` |
Si la limite est dépassée, l'API retourne :
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
```
---
## Flux de statut
```
┌─────────────────────────────────────────────────────┐
│  Marchand appelle POST /api/v2/payment               │
│                        │                             │
│              Transaction créée                       │
│              status: PENDING                         │
│                        │                             │
│         Le payeur reçoit une notification            │
│         sur son téléphone mobile                     │
│                        │                             │
│          ┌─────────────┴─────────────┐              │
│          ▼                           ▼               │
│    Payeur valide               Payeur annule         │
│          │                           │               │
│          ▼                           ▼               │
│       SUCCESS                     FAILED             │
│  Paiement effectué          Paiement échoué          │
│          │                           │               │
│          └────────────┬──────────────┘               │
│                       ▼                              │
│     Freemopay envoie un callback POST                │
│     vers l'URL webhook du marchand                   │
└─────────────────────────────────────────────────────┘
```
> Le marchand peut aussi interroger l'état à tout moment via `GET /api/v2/payment/:reference`.
---
## Endpoints
---
### 1. `POST /api/v2/payment/token` — Générer un token
Génère un Bearer Token JWT pour authentifier les appels API ultérieurs.
**URL**
```
POST https://api-v2.freemopay.com/api/v2/payment/token
```
#### En-têtes de requête
| En-tête        | Valeur             | Requis |
|----------------|--------------------|--------|
| `Content-Type` | `application/json` | ✅ Oui  |
#### Corps de la requête
```json
{
  "appKey": "<string>",
  "secretKey": "<string>"
}
```
| Champ       | Type     | Requis | Description                              |
|-------------|----------|--------|------------------------------------------|
| `appKey`    | `string` | ✅ Oui  | Clé publique de l'application marchand   |
| `secretKey` | `string` | ✅ Oui  | Clé secrète de l'application marchand    |
#### Réponses
**✅ 200 OK — Token généré avec succès**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2NvdW50SWQiOiI2NzNjNjAzZGZmZmVkNTE0ZjAzNDQyNWYiLCJpYXQiOjE3NDU2Njg2ODAsImV4cCI6MTc0NTY3MjI4MH0.tL_pBYc-y0wmRJI3vDhKpa0ohuNwV0tVXnTuMgAP_CY",
  "expires_in": 3600
}
```
| Champ          | Type      | Description                              |
|----------------|-----------|------------------------------------------|
| `access_token` | `string`  | Jeton JWT à utiliser dans les requêtes suivantes |
| `expires_in`   | `integer` | Durée de validité du token en secondes (3600 = 1h) |
**❌ 401 — Identifiants invalides**
```json
{
  "code": "BAD_API_CREDENTIALS",
  "message": {
    "en": "Invalid api key credentials",
    "fr": "Clé d'api invalide"
  }
}
```
#### Exemple cURL
```bash
curl --location 'https://api-v2.freemopay.com/api/v2/payment/token' \\
  --header 'Content-Type: application/json' \\
  --data '{
    "appKey": "votre_app_key",
    "secretKey": "votre_secret_key"
  }'
```
---
### 2. `GET /api/v2/payment/:reference` — Statut avec Bearer Token
Récupère les détails et le statut actuel d'une transaction en utilisant un token Bearer.
**URL**
```
GET https://api-v2.freemopay.com/api/v2/payment/:reference
```
#### En-têtes de requête
| En-tête         | Valeur                    | Requis |
|-----------------|---------------------------|--------|
| `Authorization` | `Bearer {{bearerToken}}`  | ✅ Oui  |
#### Paramètres de chemin (Path Variables)
| Paramètre   | Type     | Requis | Description                                 |
|-------------|----------|--------|---------------------------------------------|
| `reference` | `string` (UUID) | ✅ Oui | Référence UUID de la transaction retournée à l'initialisation |
#### Réponses
**✅ 200 OK — Transaction trouvée**
```json
{
  "reference": "62a11f7a-7c58-3efe-0000-637877bcdac4",
  "merchandRef": "12343",
  "amount": 1000,
  "status": "FAILED",
  "reason": "cancelled"
}
```
| Champ          | Type      | Description                                           |
|----------------|-----------|-------------------------------------------------------|
| `reference`    | `string`  | UUID de la transaction côté Freemopay                 |
| `merchandRef`  | `string`  | `externalId` fourni par le marchand à l'initialisation |
| `amount`       | `number`  | Montant de la transaction                             |
| `status`       | `string`  | État de la transaction : `PENDING`, `SUCCESS`, `FAILED` |
| `reason`       | `string`  | Motif de l'échec si `status = FAILED` (ex: `cancelled`) |
**❌ 401 — Non autorisé (token absent ou expiré)**
```json
{
  "message": "Unauthorized",
  "statusCode": 401
}
```
#### Exemple cURL
```bash
curl --location \\
  'https://api-v2.freemopay.com/api/v2/payment/62a11f7a-7c58-3efe-0000-637877bcdac4' \\
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```
---
### 3. `GET /api/v2/payment/:reference` — Statut avec Basic Auth
Identique à l'endpoint précédent, mais utilise l'authentification Basic Auth.
**URL**
```
GET https://api-v2.freemopay.com/api/v2/payment/:reference
```
#### En-têtes de requête
| En-tête         | Valeur                                    | Requis |
|-----------------|-------------------------------------------|--------|
| `Authorization` | `Basic base64(appKey:secretKey)`          | ✅ Oui  |
#### Paramètres de chemin (Path Variables)
| Paramètre   | Type            | Exemple                                | Description             |
|-------------|-----------------|----------------------------------------|-------------------------|
| `reference` | `string` (UUID) | `481bc3c6-d653-44f8-8c27-e6f5448fd008` | UUID de la transaction  |
#### Réponses
**✅ 200 OK**
```json
{
  "reference": "62a11f7a-7c58-3efe-0000-637877bcdac4",
  "merchandRef": "12343",
  "amount": 1000,
  "status": "FAILED",
  "reason": "cancelled"
}
```
**❌ 401 — Non autorisé**
```json
{
  "message": "Unauthorized",
  "statusCode": 401
}
```
#### Exemple cURL
```bash
curl --location \\
  'https://api-v2.freemopay.com/api/v2/payment/481bc3c6-d653-44f8-8c27-e6f5448fd008' \\
  --user 'votre_app_key:votre_secret_key'
```
---
### 4. `POST /api/v2/payment` — Initialiser un paiement avec Bearer Token
Initie une demande de paiement Mobile Money ou Orange Money auprès du payeur, avec authentification Bearer.
**URL**
```
POST https://api-v2.freemopay.com/api/v2/payment
```
#### En-têtes de requête
| En-tête         | Valeur                    | Requis |
|-----------------|---------------------------|--------|
| `Authorization` | `Bearer {{bearerToken}}`  | ✅ Oui  |
| `Content-Type`  | `application/json`        | ✅ Oui  |
#### Corps de la requête
```json
{
  "payer": "2376xxxxxxxx",
  "amount": "100",
  "externalId": "yourid2252626252",
  "description": "test",
  "callback": "https://votresite.com/webhook/freemopay"
}
```
| Champ         | Type     | Requis | Description                                                        |
|---------------|----------|--------|--------------------------------------------------------------------|
| `payer`       | `string` | ✅ Oui  | Numéro de téléphone du payeur au format international (ex: `237xxxxxxxxx`) |
| `amount`      | `string` | ✅ Oui  | Montant du paiement (en FCFA ou devise locale)                     |
| `externalId`  | `string` | ✅ Oui  | Identifiant unique côté marchand pour la réconciliation            |
| `description` | `string` | ✅ Oui  | Description affichée au payeur                                     |
| `callback`    | `string` | ✅ Oui  | URL HTTPS du webhook marchand pour recevoir les notifications      |
#### Réponses
**✅ 200 OK — Paiement initié avec succès**
```json
{
  "reference": "cecb550c-f542-4f63-abe6-40534a02ddf1",
  "status": "SUCCESS",
  "message": "Paiement initié avec success"
}
```
**Schéma de réponse (JSON Schema)**
```json
{
  "reference": "b4766726-ccbb-0000-b53c-0b387686a397",
  "status": "SUCCESS",
  "message": ""
}
```
| Champ       | Type     | Description                                                      |
|-------------|----------|------------------------------------------------------------------|
| `reference` | `string` | UUID unique de la transaction généré par Freemopay               |
| `status`    | `string` | `SUCCESS` ou `INITIALIZATION_SUCCESS` = initiation réussie ; `FAILED` = échec |
| `message`   | `string` | Message descriptif de l'opération                               |
#### Exemple cURL
```bash
curl --location 'https://api-v2.freemopay.com/api/v2/payment' \\
  --header 'Content-Type: application/json' \\
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \\
  --data '{
    "payer": "2376xxxxxxxx",
    "amount": "100",
    "externalId": "yourid2252626252",
    "description": "test",
    "callback": "https://votresite.com/webhook/freemopay"
  }'
```
---
### 5. `POST /api/v2/payment` — Initialiser un paiement avec Basic Auth
Même fonctionnement que l'endpoint précédent, avec authentification Basic Auth.
**URL**
```
POST https://api-v2.freemopay.com/api/v2/payment
```
#### En-têtes de requête
| En-tête         | Valeur                             | Requis |
|-----------------|------------------------------------|--------|
| `Authorization` | `Basic base64(appKey:secretKey)`   | ✅ Oui  |
| `Content-Type`  | `application/json`                 | ✅ Oui  |
#### Corps de la requête
```json
{
  "payer": "2376xxxxxxxx",
  "amount": "10000",
  "externalId": "yourid225262625342",
  "description": "test",
  "callback": "https://webhook.site/048fef35-a7ce-4ee2-bee1-e7b0d2be0c2a"
}
```
| Champ         | Type     | Requis | Description                                                        |
|---------------|----------|--------|--------------------------------------------------------------------|
| `payer`       | `string` | ✅ Oui  | Numéro de téléphone du payeur au format international              |
| `amount`      | `string` | ✅ Oui  | Montant du paiement                                                |
| `externalId`  | `string` | ✅ Oui  | Identifiant unique côté marchand                                   |
| `description` | `string` | ✅ Oui  | Description du paiement                                            |
| `callback`    | `string` | ✅ Oui  | URL HTTPS du webhook pour les notifications                        |
#### Réponses
**✅ 200 OK — Transaction créée**
```json
{
  "reference": "27aa4ac4-a9d1-4d63-a805-77fd0794031c",
  "status": "CREATED",
  "message": "Transaction created"
}
```
> ⚠️ Avec Basic Auth, le statut initial retourné peut être `CREATED` (au lieu de `SUCCESS`) — cela signifie que la transaction a bien été créée et est en attente de validation du payeur.
**❌ 401 — Non autorisé**
```json
{
  "message": "Unauthorized",
  "statusCode": 401
}
```
#### Exemple cURL
```bash
curl --location 'https://api-v2.freemopay.com/api/v2/payment' \\
  --header 'Content-Type: application/json' \\
  --user 'votre_app_key:votre_secret_key' \\
  --data '{
    "payer": "2376xxxxxxxx",
    "amount": "10000",
    "externalId": "yourid225262625342",
    "description": "test",
    "callback": "https://votresite.com/webhook/freemopay"
  }'
```
---
### 6. `POST Callback` — Notification webhook marchand
> ⚠️ **Ce n'est pas un endpoint Freemopay à appeler.** C'est un endpoint **que le marchand doit exposer** sur son propre serveur. Freemopay l'appellera automatiquement dès que la transaction aboutit ou échoue.
**URL (côté marchand)**
```
POST https://votresite.com/webhook/freemopay
```
#### Payload reçu (envoyé par Freemopay)
```json
{
  "status": "FAILED",
  "reference": "cecb550c-f542-4f63-abe6-40534a02ddf2",
  "amount": 100,
  "transactionType": "DEPOSIT",
  "externalId": "yourid2252626252",
  "message": "Transaction canceled by the customer."
}
```
| Champ             | Type      | Description                                                         |
|-------------------|-----------|---------------------------------------------------------------------|
| `status`          | `string`  | État **final** de la transaction : `SUCCESS` ou `FAILED`           |
| `reference`       | `string`  | UUID de la transaction Freemopay                                    |
| `amount`          | `number`  | Montant de la transaction                                           |
| `transactionType` | `string`  | Type de transaction : `DEPOSIT` (encaissement)                      |
| `externalId`      | `string`  | Identifiant interne marchand fourni à l'initialisation              |
| `message`         | `string`  | Message descriptif ou motif d'échec (ex: `Transaction canceled by the customer.`) |
#### Ce que votre webhook doit retourner
Votre endpoint doit **toujours répondre `200 OK`**, même si le paiement a échoué, afin de confirmer à Freemopay la bonne réception du callback.
```http
HTTP/1.1 200 OK
```
> Si votre webhook ne répond pas `200`, Freemopay peut tenter de renvoyer le callback.
#### Notes importantes
- Le champ `status` reflète l'**état final** (après action du payeur), contrairement au statut initial retourné lors de l'initialisation.
- Le champ `externalId` permet de **faire le lien** avec votre commande / transaction interne.
- Votre URL de callback doit être accessible publiquement en HTTPS.
#### Exemple de simulation cURL (pour tester votre webhook)
```bash
curl --location 'https://votresite.com/webhook/freemopay' \\
  --header 'Content-Type: application/json' \\
  --data '{
    "status": "FAILED",
    "reference": "cecb550c-f542-4f63-abe6-40534a02ddf2",
    "amount": 100,
    "transactionType": "DEPOSIT",
    "externalId": "yourid2252626252",
    "message": "Transaction canceled by the customer."
  }'
```
---
### 7. `POST /api/v2/payment/direct-withdraw` — Initier un retrait
Initie un retrait (cashout) vers le numéro de téléphone d'un bénéficiaire via Mobile Money.
**URL**
```
POST https://api-v2.freemopay.com/api/v2/payment/direct-withdraw
```
#### En-têtes de requête
| En-tête         | Valeur                           | Requis |
|-----------------|----------------------------------|--------|
| `Authorization` | `Basic base64(appKey:secretKey)` | ✅ Oui  |
| `Content-Type`  | `application/json`               | ✅ Oui  |
#### Corps de la requête
```json
{
  "receiver": "237695509408",
  "amount": "100",
  "externalId": "yourid225262625342",
  "callback": "https://webhook.site/048fef35-a7ce-4ee2-bee1-e7b0d2be0c2a"
}
```
| Champ        | Type     | Requis | Description                                                        |
|--------------|----------|--------|--------------------------------------------------------------------|
| `receiver`   | `string` | ✅ Oui  | Numéro de téléphone du bénéficiaire au format international        |
| `amount`     | `string` | ✅ Oui  | Montant à retirer / envoyer                                        |
| `externalId` | `string` | ✅ Oui  | Identifiant unique côté marchand pour la réconciliation            |
| `callback`   | `string` | ✅ Oui  | URL HTTPS du webhook pour recevoir la notification du statut final |
#### Réponses
**✅ 200 OK — Retrait créé avec succès**
```json
{
  "reference": "0e8d2768-e3fd-4224-b76f-3f7ae7bf9d27",
  "status": "CREATED",
  "message": "cashout created"
}
```
**Schéma de réponse (JSON Schema)**
```json
{
  "reference": "b4766726-ccbb-0000-b53c-0b387686a397",
  "status": "CREATED",
  "message": "cashout created"
}
```
| Champ       | Type     | Description                                                       |
|-------------|----------|-------------------------------------------------------------------|
| `reference` | `string` | UUID unique du retrait généré par Freemopay                       |
| `status`    | `string` | `CREATED` = retrait initié et en cours de traitement              |
| `message`   | `string` | Message de confirmation (ex: `cashout created`)                   |
#### Exemple cURL
```bash
curl --location 'https://api-v2.freemopay.com/api/v2/payment/direct-withdraw' \\
  --header 'Content-Type: application/json' \\
  --user 'votre_app_key:votre_secret_key' \\
  --data '{
    "receiver": "237695509408",
    "amount": "100",
    "externalId": "yourid225262625342",
    "callback": "https://votresite.com/webhook/freemopay"
  }'
```
---
## Codes de statut des transactions
| Statut                   | Contexte       | Signification                                              |
|--------------------------|----------------|------------------------------------------------------------|
| `PENDING`                | Paiement       | Transaction en attente de validation du payeur             |
| `CREATED`                | Paiement / Retrait | Transaction créée, en cours de traitement               |
| `SUCCESS`                | Paiement       | Paiement effectué avec succès                              |
| `INITIALIZATION_SUCCESS` | Paiement       | Demande de paiement initiée avec succès                    |
| `FAILED`                 | Paiement       | Paiement échoué ou annulé par le payeur                    |
---
## Codes d'erreur HTTP
| Code HTTP | Signification          | Cause probable                                     | Solution                                    |
|-----------|------------------------|-----------------------------------------------------|---------------------------------------------|
| `200 OK`  | Succès                 | Requête traitée avec succès                         | —                                           |
| `401 Unauthorized` | Non autorisé  | Token absent, expiré ou identifiants incorrects    | Vérifier `appKey`, `secretKey` ou regénérer le token |
| `429 Too Many Requests` | Limite atteinte | Plus de 100 requêtes/min                    | Attendre le délai indiqué dans `Retry-After` |
### Réponse 401 détaillée
```json
{
  "message": "Unauthorized",
  "statusCode": 401
}
```
### Réponse 429 — En-têtes
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
Content-Type: application/json
```
---
## Récapitulatif des endpoints
| # | Méthode | Endpoint                                  | Auth          | Description                           |
|---|---------|-------------------------------------------|---------------|---------------------------------------|
| 1 | `POST`  | `/api/v2/payment/token`                   | Aucune        | Générer un Bearer Token JWT           |
| 2 | `GET`   | `/api/v2/payment/:reference`              | Bearer Token  | Statut d'un paiement                  |
| 3 | `GET`   | `/api/v2/payment/:reference`              | Basic Auth    | Statut d'un paiement                  |
| 4 | `POST`  | `/api/v2/payment`                         | Bearer Token  | Initialiser un paiement               |
| 5 | `POST`  | `/api/v2/payment`                         | Basic Auth    | Initialiser un paiement               |
| 6 | `POST`  | `https://votresite.com/webhook/freemopay` | Aucune (reçu) | Callback notification (côté marchand) |
| 7 | `POST`  | `/api/v2/payment/direct-withdraw`         | Basic Auth    | Initier un retrait (cashout)          |