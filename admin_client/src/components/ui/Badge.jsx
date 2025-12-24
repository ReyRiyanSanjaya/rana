import * as React from "react"
import { cva } from "class-variance-authority"
import { cn } from "../../lib/utils"

const badgeVariants = cva(
    "inline-flex items-center rounded-full border border-slate-200 px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-slate-950 focus:ring-offset-2",
    {
        variants: {
            variant: {
                default:
                    "border-transparent bg-slate-900 text-slate-50 hover:bg-slate-900/80",
                secondary:
                    "border-transparent bg-slate-100 text-slate-900 hover:bg-slate-100/80",
                destructive:
                    "border-transparent bg-red-500 text-slate-50 hover:bg-red-500/80",
                outline: "text-slate-950",
                success: "border-transparent bg-green-50 text-green-700 hover:bg-green-50/80 border-green-200", // Custom
                warning: "border-transparent bg-yellow-50 text-yellow-700 hover:bg-yellow-50/80 border-yellow-200", // Custom
                error: "border-transparent bg-red-50 text-red-700 hover:bg-red-50/80 border-red-200", // Custom
                brand: "border-transparent bg-blue-50 text-blue-700 hover:bg-blue-50/80 border-blue-200", // Custom
                neutral: "border-transparent bg-slate-100 text-slate-700 hover:bg-slate-100/80 border-slate-200", // Custom
            },
        },
        defaultVariants: {
            variant: "default",
        },
    }
)

function Badge({ className, variant, icon: Icon, children, ...props }) {
    // Map legacy variants if needed (though I added them as custom variants above)
    return (
        <div className={cn(badgeVariants({ variant }), className)} {...props}>
            {Icon && <Icon className="w-3 h-3 mr-1" />}
            {children}
        </div>
    )
}

export { Badge, badgeVariants }
export default Badge
