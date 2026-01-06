import * as React from "react"
import { Loader2 } from "lucide-react"
import { Slot } from "@radix-ui/react-slot"
import { cva } from "class-variance-authority"
import { cn } from "../../lib/utils"

const buttonVariants = cva(
    "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-xl text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary-500 disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0",
    {
        variants: {
            variant: {
                default:
                    "bg-primary-200 text-primary-900 shadow hover:bg-primary-300",
                destructive:
                    "bg-red-100 text-red-700 shadow-sm hover:bg-red-200",
                outline:
                    "border border-primary-300 bg-white text-primary-800 shadow-sm hover:bg-primary-50",
                secondary:
                    "bg-primary-100 text-primary-900 shadow-sm hover:bg-primary-200",
                ghost: "text-primary-800 hover:bg-primary-50",
                link: "text-primary-700 underline-offset-4 hover:underline",
            },
            size: {
                default: "h-9 px-4 py-2",
                sm: "h-8 rounded-lg px-3 text-xs",
                lg: "h-10 rounded-xl px-8",
                icon: "h-9 w-9",
            },
        },
        defaultVariants: {
            variant: "default",
            size: "default",
        },
    }
)

const Button = React.forwardRef(({ className, variant, size, asChild = false, isLoading, icon: Icon, children, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
        <Comp
            className={cn(buttonVariants({ variant, size, className }))}
            ref={ref}
            disabled={isLoading || props.disabled}
            {...props}
        >
            {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {!isLoading && Icon && <Icon className="mr-2 h-4 w-4" />}
            {children}
        </Comp>
    )
})
Button.displayName = "Button"

export { Button, buttonVariants }
export default Button

