<script>
  import Hero from "./components/Hero.svelte";
  import FeatureGrid from "./components/FeatureGrid.svelte";
  import PricingCalculator from "./components/PricingCalculator.svelte";
</script>

<main>
  <Hero />
  <FeatureGrid />
  <PricingCalculator />
  <footer>
    <p>© 2026 Peonware, Inc. All rights reserved.</p>
    <a href="#top">Back to top</a>
  </footer>
</main>

<style>
  :global(*), :global(*::before), :global(*::after) {
    box-sizing: border-box;
  }
  :global(body) {
    margin: 0;
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #0f172a;
    background: #f8fafc;
    line-height: 1.5;
  }
  :global(a) {
    color: #2563eb;
  }
  main {
    max-width: 1100px;
    margin: 0 auto;
    padding: 0 1.5rem 3rem;
  }
  footer {
    margin-top: 4rem;
    padding: 2rem 0;
    border-top: 1px solid #e2e8f0;
    text-align: center;
    color: #64748b;
    font-size: 0.9rem;
  }
  footer a {
    display: inline-block;
    margin-top: 0.5rem;
  }
</style>
