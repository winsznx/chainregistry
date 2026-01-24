/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    transpilePackages: ['@chainregistry/shared', '@chainregistry/base-adapter', '@chainregistry/stacks-adapter'],
};

export default nextConfig;
