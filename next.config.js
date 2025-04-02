/** @type {import("next").NextConfig} */
module.exports = {
  reactStrictMode: true,
  images: {
    domains: ["gateway.pinata.cloud", "res.cloudinary.com"], // Add Cloudinary
    formats: ["image/webp"],
  },
};
