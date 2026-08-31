<section class="hero" aria-labelledby="hero-title">
  <div class="hero-content">
    <h1 id="hero-title">Peonware Pricing</h1>
    <p class="subtitle">Simple, transparent pricing that scales with your team. No hidden fees.</p>
    <div class="ctas">
      <a href="#pricing" class="btn primary">Calculate your price</a>
      <a href="#features" class="btn secondary">Compare features</a>
    </div>
  </div>
  <div class="hero-visual" aria-hidden="true">
    <div class="card">
      <div class="card-header">Peonware</div>
      <div class="card-body">
        <div class="bar" style="width: 80%"></div>
        <div class="bar" style="width: 60%"></div>
        <div class="bar" style="width: 90%"></div>
      </div>
    </div>
  </div>
</section>

<style>
  .hero {
    display: grid;
    grid-template-columns: 1.2fr 0.8fr;
    gap: 2rem;
    align-items: center;
    padding: 4rem 0 3rem;
  }
  h1 {
    font-size: 3rem;
    line-height: 1.1;
    margin: 0 0 1rem;
    letter-spacing: -0.02em;
  }
  .subtitle {
    font-size: 1.2rem;
    color: #475569;
    margin: 0 0 1.5rem;
    max-width: 36ch;
  }
  .ctas {
    display: flex;
    gap: 0.75rem;
    flex-wrap: wrap;
  }
  .btn {
    display: inline-block;
    padding: 0.75rem 1.25rem;
    border-radius: 0.5rem;
    font-weight: 600;
    text-decoration: none;
    border: 1px solid transparent;
  }
  .btn:focus-visible {
    outline: 2px solid #2563eb;
    outline-offset: 2px;
  }
  .primary {
    background: #0f172a;
    color: white;
  }
  .primary:hover {
    background: #1e293b;
  }
  .secondary {
    background: white;
    border-color: #e2e8f0;
    color: #0f172a;
  }
  .secondary:hover {
    background: #f1f5f9;
  }
  .hero-visual {
    display: flex;
    justify-content: center;
  }
  .card {
    width: 100%;
    max-width: 320px;
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 0.75rem;
    box-shadow: 0 10px 30px rgba(15,23,42,0.08);
    overflow: hidden;
  }
  .card-header {
    padding: 1rem;
    font-weight: 700;
    border-bottom: 1px solid #f1f5f9;
  }
  .card-body {
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }
  .bar {
    height: 12px;
    background: linear-gradient(90deg, #2563eb, #7c3aed);
    border-radius: 999px;
  }
  @media (max-width: 800px) {
    .hero {
      grid-template-columns: 1fr;
      padding: 2.5rem 0 2rem;
    }
    h1 {
      font-size: 2.25rem;
    }
  }
</style>
