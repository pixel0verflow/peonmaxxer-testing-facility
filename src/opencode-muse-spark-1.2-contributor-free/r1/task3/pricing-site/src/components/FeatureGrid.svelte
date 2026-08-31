<script>
  import featuresData from "../../data/features.json";
</script>

<section id="features" aria-labelledby="features-title">
  <h2 id="features-title">Compare plans</h2>
  <p class="intro">Everything you need — pick the plan that fits your team.</p>

  <div class="table-wrapper">
    <table>
      <caption class="visually-hidden">Feature comparison by plan</caption>
      <thead>
        <tr>
          <th scope="col">Feature</th>
          {#each featuresData.plans as plan}
            <th scope="col">{plan}</th>
          {/each}
        </tr>
      </thead>
      <tbody>
        {#each featuresData.features as feature}
          <tr>
            <th scope="row">{feature.name}</th>
            {#each featuresData.plans as plan}
              <td>{feature[plan]}</td>
            {/each}
          </tr>
        {/each}
      </tbody>
    </table>
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
  .table-wrapper {
    overflow-x: auto;
    border: 1px solid #e2e8f0;
    border-radius: 0.75rem;
    background: white;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    min-width: 500px;
  }
  caption.visually-hidden {
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
  th, td {
    padding: 0.9rem 1rem;
    text-align: left;
    border-bottom: 1px solid #f1f5f9;
  }
  thead th {
    background: #f8fafc;
    font-weight: 700;
    text-transform: capitalize;
    font-size: 0.95rem;
  }
  thead th:first-child {
    text-transform: none;
  }
  tbody th {
    font-weight: 600;
    color: #0f172a;
    background: white;
  }
  tbody tr:last-child th,
  tbody tr:last-child td {
    border-bottom: none;
  }
  td {
    color: #334155;
  }
  tbody tr:hover td,
  tbody tr:hover th {
    background: #f8fafc;
  }
</style>
