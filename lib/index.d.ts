declare module "json-diff" {
    interface Options {
        color: boolean;
        full: boolean;
    }
    export function diff(obj1: JSON, obj2: JSON, options: Options): JSON;
    export function diffString(obj1: JSON, obj2: JSON, options: Options): string;
}