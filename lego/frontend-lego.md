# Frontend "Lego" Guide: Switching Heads

This project demonstrates the **Headless** nature of the Microservices architecture. The Frontend is just a consumer of the Backend APIs, meaning you can swap it out completely without touching the core logic.

## 🔄 The Switch: Flutter to Next.js

We recently performed a "Lego swap" by replacing the Mobile App (Flutter) with a Web App (Next.js).

### Why Next.js?
*   **SEO:** Better for public product verification pages.
*   **Web Native:** No installation required for consumers.
*   **Performance:** Server-Side Rendering (SSR) and Edge capability.

### Architecture Independence
The Backend (Go) exposes standard REST endpoints:
*   `POST /products`: Used by the Producer page.
*   `GET /products/:id`: Used by the Consumer page.

This contract allows the frontend to be built in *any* technology (React, Vue, Swift, Kotlin, etc.) as long as it respects the HTTP contract.

## 🚀 Running the Next.js Frontend

1.  **Navigate to the directory:**
    ```bash
    cd frontend/web_app
    ```

2.  **Install Dependencies:**
    ```bash
    npm install
    ```

3.  **Run Development Server:**
    ```bash
    npm run dev
    ```
    Acces at `http://localhost:3000`.

## 🛠 Tech Stack
*   **Framework:** Next.js 15 (App Router).
*   **Styling:** Tailwind CSS v4 + Glassmorphism.
*   **Animations:** Framer Motion.
*   **Icons:** Lucide React.
