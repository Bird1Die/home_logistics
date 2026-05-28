# Home Logistics

Flutter web app per inventario casa, categorie, negozi e liste della spesa.

## Supabase Setup

1. Crea un progetto su Supabase.
2. Vai su `SQL Editor`.
3. Incolla ed esegui tutto il contenuto di `supabase_schema.sql`.
4. Vai su `Authentication > Providers`.
5. Abilita `Email` con password o magic link.
6. Vai su `Project Settings > API`.
7. Copia:
   - `Project URL`
   - `anon public key`

Non usare mai la `service_role key` nel frontend.

## Run Web App

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="YOUR_ANON_KEY"
```

Senza queste due variabili l'app usa ancora lo storage locale/fallback, utile per sviluppo e test.

## Security

Lo schema Supabase abilita Row Level Security su tutte le tabelle.

Ogni tabella contiene `user_id` e ogni policy limita lettura/scrittura a:

```sql
auth.uid() = user_id
```

Quindi ogni account vede e modifica solo i propri dati.

## Tests

```bash
flutter test
flutter analyze
```
