import express from 'express';
import cors from 'cors';

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// API Endpoints placeholder
app.get('/api/health', (req, res) => {
    res.json({ status: "ok" });
});

// Nanti Anda akan mengirimkan codingan koneksi Firebase Firestore di sini.
// Kita akan menambahkan script "sg1-premium-01" dan service account credentials Firestore
// yang bertugas menarik data/perintah (sync) dari Web Panel Utama Anda.

if (process.env.NODE_ENV !== "production") {
    import('vite').then(async (vite) => {
        const viteServer = await vite.createServer({
            server: { middlewareMode: true },
            appType: "spa",
        });
        app.use(viteServer.middlewares);
    });
} else {
    // Production static files
}

app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server API berjalan di port ${PORT}`);
});
