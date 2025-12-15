import { QRCodeSVG } from 'qrcode.react';

interface ProductQRCodeProps {
    productId: string;
    size?: number;
}

export const ProductQRCode: React.FC<ProductQRCodeProps> = ({ productId, size = 128 }) => {
    // Construct the verification URL
    // Ideally this should be an absolute URL to the verification page
    const verificationUrl = `${typeof window !== 'undefined' ? window.location.origin : ''}/verify/${productId}`;

    return (
        <div className="flex flex-col items-center p-4 bg-white rounded-xl shadow-sm border border-gray-100">
            <QRCodeSVG
                value={verificationUrl}
                size={size}
                level="H" // High error correction level
                includeMargin={true}
                className="mb-2"
            />
            <p className="text-xs text-gray-500 font-mono mt-2">{productId}</p>
        </div>
    );
};
