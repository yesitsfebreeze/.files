import { createMDX } from 'fumadocs-mdx/next';

// agentRules off: this repo's AGENTS.md at the root is the working
// contract, and fumadocs would drop a second one in here on every dev run.
const withMDX = createMDX({ agentRules: false });

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
};

export default withMDX(config);
