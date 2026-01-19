# Risoluzione dell'errore NFC Plugin

L'errore `MissingPluginException: No implementation found for method Nfc#isAvailable` significa che il plugin NFC non è stato compilato per la piattaforma nativa.

## Soluzione:

### Per Android:
1. Apri il terminale nella cartella del progetto
2. Esegui:
   ```bash
   flutter clean
   ```
3. Se il clean non funziona a causa di permessi, elimina manualmente:
   - Cartella `.dart_tool`
   - Cartella `build`
   - Cartella `android/.gradle` (se esiste)

4. Ricompila il progetto:
   ```bash
   flutter pub get
   flutter run
   ```

### Per iOS:
1. Cancella la cartella `ios/Pods`
2. Esegui:
   ```bash
   flutter pub get
   cd ios
   pod install --repo-update
   cd ..
   flutter run
   ```

### Permessi Android richiesti:
Il file `android/app/src/main/AndroidManifest.xml` dovrebbe contenere:
```xml
<uses-permission android:name="android.permission.NFC" />
```

### Permessi iOS richiesti:
Il file `ios/Runner/Info.plist` dovrebbe contenere:
```xml
<key>NFCReaderUsageDescription</key>
<string>Questa app usa NFC per leggere le tue carte</string>
```

## Testing:
Dopo la ricompilazione, il pulsante NFC nella sezione Preferenze dovrebbe funzionare correttamente.
