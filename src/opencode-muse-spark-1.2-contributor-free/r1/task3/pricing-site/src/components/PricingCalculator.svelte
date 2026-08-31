<script>
  import { computePrice, RATES_CENTS } from "../lib/pricing.js";
  import featuresData from "../../data/features.json";

  let plan = $state("team");
  let seatsRaw = $state("5");
  let months = $state(1);
  let sso = $state(false);
  let backup = $state(false);

  let addons = $derived(
    [
      sso ? { id: "sso", pricePerMonth: 25 } : null,
      backup ? { id: "backup", pricePerMonth: 4.99 } : null,
    ].filter(Boolean)
  );

  let result = $derived.by(() => {
    try {
      const trimmed = seatsRaw.trim();
      if (trimmed === "") {
        throw new Error(`Invalid seats: ${seatsRaw}`);
      }
      const nSeats = Number(trimmed);
      if (!Number.isFinite(nSeats)) {
        throw new Error(`Invalid seats: ${seatsRaw}`);
      }
      return computePrice({ plan, seats: nSeats, months, addons });
    } catch (e) {
      return { error: e.message };
    }
  });

  function handleSeatsInput(e) {
    seatsRaw = e.currentTarget.value;
  }

  let isAnnual = $derived(months === 12);
</script>

<section id="pricing" aria-labelledby="pricing-title">
  <h2 id="pricing-title">Pricing calculator</h2>
  <p class="intro">Choose your plan, seats, and add-ons. Annual billing saves 20%.</p>

  <div class="calculator">
    <form class="controls" onsubmit={(e)=>e.preventDefault()} aria-describedby="price-summary">
      <fieldset>
        <legend>Plan</legend>
        <div class="plan-options" role="radiogroup" aria-label="Select plan">
          {#each featuresData.plans as p}
            <label class="radio-card" class:selected={plan===p}>
              <input
                type="radio"
                name="plan"
                value={p}
                checked={plan===p}
                onchange={() => plan = p}
              />
              <span class="plan-name">{p}</span>
              <span class="plan-price">
                ${RATES_CENTS[p] / 100}
                <span class="per">/seat/mo</span>
              </span>
            </label>
          {/each}
        </div>
      </fieldset>

      <div class="field">
        <label for="seats">Seats</label>
        <input
          id="seats"
          type="number"
          min="1"
          step="1"
          inputmode="numeric"
          value={seatsRaw}
          oninput={handleSeatsInput}
          aria-describedby="seats-help"
        />
        <p id="seats-help" class="help">Volume discounts: 11–50 seats 10% off, 51+ seats 25% off (marginal).</p>
      </div>

      <fieldset>
        <legend>Billing period</legend>
        <div class="billing-toggle">
          <label class="toggle">
            <input
              type="checkbox"
              role="switch"
              aria-label="Annual billing"
              checked={isAnnual}
              onchange={(e) => months = e.currentTarget.checked ? 12 : 1}
            />
            <span>Annual billing</span>
          </label>
          <span class="badge">Save 20%</span>
          <span class="billing-label">
            {#if isAnnual}Billed annually (12 months){:else}Monthly billing{/if}
          </span>
        </div>
      </fieldset>

      <fieldset>
        <legend>Add-ons</legend>
        <div class="addons">
          <label class="checkbox">
            <input type="checkbox" checked={sso} onchange={(e)=> sso = e.currentTarget.checked} />
            <span>SSO $25/mo</span>
          </label>
          <label class="checkbox">
            <input type="checkbox" checked={backup} onchange={(e)=> backup = e.currentTarget.checked} />
            <span>Backup $4.99/mo</span>
          </label>
        </div>
      </fieldset>
    </form>

    <div class="summary" id="price-summary" aria-live="polite">
      {#if result.error}
        <p class="error" role="alert">Error: {result.error}</p>
      {:else}
        <div class="price-row">
          <span class="label">Monthly</span>
          <span class="value">${result.monthly.toFixed(2)}/mo</span>
        </div>
        <div class="price-row total">
          <span class="label">
            {#if months===12}Total for 12 months{:else}Total{/if}
          </span>
          <span class="value">${result.total.toFixed(2)}</span>
        </div>
        {#if result.savings > 0}
          <p class="savings">You save ${result.savings.toFixed(2)} {months===12 ? 'with volume + annual discounts' : 'with volume discounts'}.</p>
        {:else}
          <p class="savings muted">No savings yet — add more seats or switch to annual.</p>
        {/if}
        {#if months===12}
          <p class="note">Annual discount applied to seats + add-ons.</p>
        {/if}
      {/if}
    </div>
  </div>
</section>

<style>
  section {
    padding: 2rem 0;
  }
  h2 {
    font-size: 1.75rem;
    margin: 0 0 0.5rem;
  }
  .intro {
    color: #475569;
    margin: 0 0 1.5rem;
  }
  .calculator {
    display: grid;
    grid-template-columns: 1.2fr 0.8fr;
    gap: 1.5rem;
    align-items: start;
  }
  .controls {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 0.75rem;
    padding: 1.25rem;
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }
  fieldset {
    border: none;
    padding: 0;
    margin: 0;
  }
  legend {
    font-weight: 600;
    margin-bottom: 0.5rem;
    font-size: 0.95rem;
  }
  .plan-options {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.5rem;
  }
  .radio-card {
    border: 1px solid #e2e8f0;
    border-radius: 0.5rem;
    padding: 0.75rem;
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    cursor: pointer;
    position: relative;
  }
  .radio-card.selected {
    border-color: #2563eb;
    background: #eff6ff;
  }
  .radio-card:focus-within {
    outline: 2px solid #2563eb;
    outline-offset: 2px;
  }
  .radio-card input {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }
  .plan-name {
    text-transform: capitalize;
    font-weight: 600;
  }
  .plan-price {
    font-size: 0.9rem;
    color: #334155;
  }
  .per {
    color: #64748b;
    font-weight: 400;
  }
  .field {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
  }
  label[for="seats"] {
    font-weight: 600;
    font-size: 0.95rem;
  }
  input[type="number"] {
    padding: 0.6rem 0.75rem;
    border: 1px solid #cbd5e1;
    border-radius: 0.5rem;
    font-size: 1rem;
    width: 100%;
    max-width: 160px;
  }
  input[type="number"]:focus-visible {
    outline: 2px solid #2563eb;
    outline-offset: 2px;
    border-color: #2563eb;
  }
  .help {
    font-size: 0.8rem;
    color: #64748b;
    margin: 0;
  }
  .billing-toggle {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex-wrap: wrap;
  }
  .toggle {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    font-weight: 500;
  }
  .toggle input[type="checkbox"] {
    width: 44px;
    height: 24px;
    appearance: none;
    background: #cbd5e1;
    border-radius: 999px;
    position: relative;
    cursor: pointer;
    transition: background 0.2s;
  }
  .toggle input[type="checkbox"]::after {
    content: "";
    position: absolute;
    top: 2px;
    left: 2px;
    width: 20px;
    height: 20px;
    background: white;
    border-radius: 50%;
    transition: transform 0.2s;
    box-shadow: 0 1px 2px rgba(0,0,0,0.15);
  }
  .toggle input[type="checkbox"]:checked {
    background: #2563eb;
  }
  .toggle input[type="checkbox"]:checked::after {
    transform: translateX(20px);
  }
  .toggle input[type="checkbox"]:focus-visible {
    outline: 2px solid #2563eb;
    outline-offset: 2px;
  }
  .badge {
    background: #dcfce7;
    color: #166534;
    font-size: 0.75rem;
    font-weight: 700;
    padding: 0.15rem 0.4rem;
    border-radius: 999px;
  }
  .billing-label {
    font-size: 0.85rem;
    color: #475569;
  }
  .addons {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  .checkbox {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    padding: 0.5rem;
    border: 1px solid #e2e8f0;
    border-radius: 0.5rem;
  }
  .checkbox:has(input:checked) {
    border-color: #2563eb;
    background: #eff6ff;
  }
  .checkbox input:focus-visible {
    outline: 2px solid #2563eb;
    outline-offset: 2px;
  }
  .summary {
    background: #0f172a;
    color: white;
    border-radius: 0.75rem;
    padding: 1.5rem;
    min-height: 200px;
  }
  .price-row {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    padding: 0.5rem 0;
    border-bottom: 1px solid rgba(255,255,255,0.1);
  }
  .price-row.total {
    font-weight: 700;
    font-size: 1.15rem;
    border-bottom: none;
    padding-top: 0.75rem;
  }
  .label {
    color: #cbd5e1;
  }
  .value {
    font-variant-numeric: tabular-nums;
  }
  .savings {
    margin: 1rem 0 0;
    background: rgba(34,197,94,0.15);
    color: #bbf7d0;
    padding: 0.6rem 0.75rem;
    border-radius: 0.5rem;
    font-size: 0.9rem;
  }
  .savings.muted {
    background: rgba(255,255,255,0.08);
    color: #94a3b8;
  }
  .note {
    margin: 0.5rem 0 0;
    font-size: 0.8rem;
    color: #94a3b8;
  }
  .error {
    color: #fecaca;
    background: rgba(239,68,68,0.15);
    padding: 0.75rem;
    border-radius: 0.5rem;
  }
  @media (max-width: 800px) {
    .calculator {
      grid-template-columns: 1fr;
    }
    .plan-options {
      grid-template-columns: 1fr;
    }
  }
</style>
